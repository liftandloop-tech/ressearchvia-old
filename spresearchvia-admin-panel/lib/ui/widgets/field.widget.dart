import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';

class TextFieldController extends GetxController {
  var obscureText = true.obs;

  void toggleObscure() {
    obscureText.value = !obscureText.value;
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Widget? prefixIcon;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final textFieldController = Get.put(
      TextFieldController(),
      tag: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray700,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Obx(
          () => TextFormField(
            controller: controller,
            validator: validator,
            onFieldSubmitted: onFieldSubmitted,
            obscureText: isPassword
                ? textFieldController.obscureText.value
                : false,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.gray400),
              filled: true,
              fillColor: AppTheme.white,
              prefixIcon: prefixIcon,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        textFieldController.obscureText.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.gray500,
                        size: 18,
                      ),
                      onPressed: textFieldController.toggleObscure,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.gray300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.gray300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: AppTheme.primaryBlue,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.errorRed),
              ),
              counterText: maxLength != null ? null : '',
            ),
          ),
        ),
      ],
    );
  }
}
