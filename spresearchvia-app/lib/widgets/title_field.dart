import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../core/utils/responsive.dart';
import '../core/constants/app_dimensions.dart';
import '../core/theme/app_theme.dart';

class TitleFieldController extends GetxController {
  final RxBool obscure;

  TitleFieldController({required bool isPasswordField})
    : obscure = isPasswordField.obs;

  void toggleObscure() {
    obscure.value = !obscure.value;
  }
}

class TitleField extends StatelessWidget {
  const TitleField({
    super.key,
    required this.title,
    required this.controller,
    this.hint,
    this.icon,
    this.isPasswordField = false,
    this.focusNode,
    this.inputFormatters,
    this.keyboardType,
    this.maxLength,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.errorText,
  });

  final String title;
  final String? hint;
  final String? errorText;
  final TextEditingController controller;
  final IconData? icon;
  final bool isPasswordField;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool readOnly;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final fieldController = Get.put(
      TitleFieldController(isPasswordField: isPasswordField),
      tag: controller.hashCode.toString(),
    );

    final textStyle = TextStyle(
      fontSize: responsive.sp(14),
      color: AppTheme.primaryBlue,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w400,
    );

    final hintStyle = TextStyle(
      fontSize: responsive.sp(14),
      color: AppTheme.textGreyLight,
      fontFamily: 'Poppins',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppTheme.primaryBlue,
            fontSize: responsive.sp(14),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: responsive.spacing(5)),
        Container(
          height: responsive.spacing(AppDimensions.containerSmall),
          padding: responsive.padding(horizontal: AppDimensions.spacing10),
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xffEFEFEF) : const Color(0xffF9FAFB),
            border: Border.all(
              width: AppDimensions.borderThin,
              color: AppTheme.borderGrey,
            ),
            borderRadius: BorderRadius.circular(
              responsive.radius(AppDimensions.radiusMedium),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: isPasswordField
                ? Obx(
                    () => TextField(
                      controller: controller,
                      focusNode: focusNode,
                      obscureText: fieldController.obscure.value,
                      inputFormatters: inputFormatters,
                      keyboardType: keyboardType,
                      maxLength: maxLength,
                      readOnly: readOnly,
                      enabled: !readOnly,
                      textCapitalization: textCapitalization,
                      style: textStyle,
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: hintStyle,
                        border: InputBorder.none,
                        counterText: '',
                        suffixIcon: GestureDetector(
                          onTap: fieldController.toggleObscure,
                          child: Icon(
                            fieldController.obscure.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: responsive.spacing(AppDimensions.iconMedium),
                          ),
                        ),
                      ),
                    ),
                  )
                : TextField(
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: false,
                    inputFormatters: inputFormatters,
                    keyboardType: keyboardType,
                    maxLength: maxLength,
                    readOnly: readOnly,
                    enabled: !readOnly,
                    textCapitalization: textCapitalization,
                    style: textStyle,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: hintStyle,
                      border: InputBorder.none,
                      counterText: '',
                      suffixIcon: icon != null
                          ? Icon(
                              icon,
                              size: responsive.spacing(
                                AppDimensions.iconMedium,
                              ),
                            )
                          : null,
                    ),
                  ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: responsive.spacing(4)),
          Padding(
            padding: EdgeInsets.only(left: responsive.spacing(4)),
            child: Text(
              errorText!,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.error,
                fontSize: responsive.sp(12),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
