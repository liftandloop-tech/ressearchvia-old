import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import '../../../widgets/dropdown.widget.dart';

class PlanFilters extends StatelessWidget {
  final String selectedStatus;
  final TextEditingController searchController;
  final Function(String?) onStatusChanged;
  final VoidCallback onApply;
  final VoidCallback onReset;

  const PlanFilters({
    super.key,
    required this.selectedStatus,
    required this.searchController,
    required this.onStatusChanged,
    required this.onApply,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search Plan', style: AppTheme.labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      decoration:
                          AppTheme.inputDecoration(
                            'Search plan name...',
                          ).copyWith(
                            prefixIcon: const Icon(Icons.search, size: 20),
                          ),
                      onSubmitted: (_) => onApply(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status', style: AppTheme.labelStyle),
                    const SizedBox(height: 8),
                    Dropdown(
                      value: selectedStatus,
                      items: ['All Status', 'Active', 'Inactive'],
                      onChanged: onStatusChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: onApply,
                        style: AppTheme.greenButtonStyle.copyWith(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                          ),
                        ),
                        child: const Text('Apply'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onReset,
                        style: AppTheme.secondaryButtonStyle.copyWith(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                          ),
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
