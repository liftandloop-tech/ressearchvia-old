import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class PlanFeaturesSection extends StatelessWidget {
  final List<String> features;
  final Function(String) onAddFeature;
  final Function(String) onRemoveFeature;

  const PlanFeaturesSection({
    super.key,
    required this.features,
    required this.onAddFeature,
    required this.onRemoveFeature,
  });

  @override
  Widget build(BuildContext context) {
    final featureController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Plan Features',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
                fontFamily: 'Poppins',
              ),
            ),
            GestureDetector(
              onTap: () {
                if (featureController.text.isNotEmpty) {
                  onAddFeature(featureController.text);
                  featureController.clear();
                }
              },
              child: Row(
                children: [
                  Icon(Icons.add, size: 16, color: AppTheme.successGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Add Feature',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: featureController,
                decoration: InputDecoration(
                  hintText: 'Feature name',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: AppTheme.gray400,
                    fontFamily: 'Poppins',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AppTheme.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AppTheme.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: AppTheme.primaryBlue,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: TextStyle(fontSize: 13, fontFamily: 'Poppins'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => onRemoveFeature(''),
              icon: Icon(Icons.delete, size: 18, color: AppTheme.errorRed),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
        if (features.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.gray50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.gray200),
                      ),
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => onRemoveFeature(feature),
                    icon: Icon(
                      Icons.delete,
                      color: AppTheme.errorRed,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
