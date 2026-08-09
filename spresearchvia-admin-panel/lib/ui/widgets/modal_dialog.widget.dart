import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';

class ModalDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double? width;
  final Widget content;
  final List<Widget>? actions;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const ModalDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.width,
    required this.content,
    this.actions,
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: width ?? AppTheme.modalWidthMedium,
        decoration: AppTheme.modalDecoration,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.h2Style.copyWith(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(subtitle!, style: AppTheme.bodySmallStyle),
                      ],
                    ],
                  ),
                ),
                if (showCloseButton)
                  IconButton(
                    onPressed: onClose ?? () => Get.back(),
                    icon: const Icon(Icons.close, size: 24),
                    color: AppTheme.gray500,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            content,

            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int i = 0; i < actions!.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    actions![i],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
