import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spresearch_web/config/theme.config.dart';

class EditableRow extends StatelessWidget {
  final String label;
  final String value;
  final TextEditingController controller;
  final bool isEditing;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const EditableRow({
    super.key,
    required this.label,
    required this.value,
    required this.controller,
    required this.isEditing,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTheme.bodySmallStyle.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: isEditing
                ? TextField(
                    controller: controller,
                    inputFormatters: inputFormatters,
                    textCapitalization: textCapitalization,
                    style: AppTheme.bodySmallStyle.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: AppTheme.spacing8,
                        horizontal: AppTheme.spacing12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusTiny,
                        ),
                        borderSide: BorderSide(color: AppTheme.gray300),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: AppTheme.bodySmallStyle.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
