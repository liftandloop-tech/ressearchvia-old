import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/subscription/pending_bank_transfers.controller.dart';

// Helper widget for filter trigger icon in table header
class _PaymentFilterTrigger extends StatelessWidget {
  final bool active;
  final String tooltip;

  const _PaymentFilterTrigger({
    required this.active,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.filter_alt,
              size: 14,
              color: active ? AppTheme.primaryBlue : AppTheme.gray400,
            ),
            if (active)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper for popup container header
Widget _buildPopupHeader(String title, bool active) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      if (active)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Active',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
    ],
  );
}

// Helper for section title
Widget _buildSectionLabel(String label) {
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    ),
  );
}

// Helper for radio option row
Widget _buildRadioItem({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
  String? badge,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 15,
            color: isSelected ? AppTheme.primaryBlue : AppTheme.gray400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                badge,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ),
        ],
      ),
    ),
  );
}

// Helper for popup action buttons
Widget _buildPopupActions({
  required BuildContext context,
  required VoidCallback onClear,
  required VoidCallback onApply,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      TextButton(
        onPressed: () {
          onClear();
          Navigator.pop(context);
        },
        child: const Text(
          'Clear',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.errorRed,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(width: 8),
      ElevatedButton(
        onPressed: () {
          onApply();
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: const Text(
          'Apply',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

// ==========================================
// 1. Customer Column Filter
// ==========================================
class PaymentCustomerFilter extends StatelessWidget {
  final PendingBankTransfersController controller;

  const PaymentCustomerFilter({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.customerFilter.value.trim().isNotEmpty;

      return PopupMenuButton<void>(
        tooltip: 'Filter by Customer',
        offset: const Offset(0, 26),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: _PaymentFilterTrigger(
          active: active,
          tooltip: 'Filter by Customer',
        ),
        itemBuilder: (context) {
          final textCtrl = TextEditingController(text: controller.customerFilter.value);

          return [
            PopupMenuItem<void>(
              enabled: false,
              child: StatefulBuilder(
                builder: (context, setStatePopup) {
                  return GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 270,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPopupHeader('Filter by Customer', active),
                          const SizedBox(height: 12),
                          TextField(
                            controller: textCtrl,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search name, phone, email...',
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 16,
                                color: AppTheme.gray500,
                              ),
                              suffixIcon: textCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        setStatePopup(() {
                                          textCtrl.clear();
                                        });
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: AppTheme.gray300),
                              ),
                            ),
                            style: const TextStyle(fontSize: 13),
                            onChanged: (_) => setStatePopup(() {}),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Filters customer name, email or phone',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          _buildPopupActions(
                            context: context,
                            onClear: () {
                              controller.customerFilter.value = '';
                              controller.applyFilters();
                            },
                            onApply: () {
                              controller.customerFilter.value = textCtrl.text.trim();
                              controller.applyFilters();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ];
        },
      );
    });
  }
}

// ==========================================
// 2. Total Paid (LTV) Column Filter
// ==========================================
class PaymentTotalPaidFilter extends StatelessWidget {
  final PendingBankTransfersController controller;

  const PaymentTotalPaidFilter({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.balanceStatusFilter.value != 'All' ||
          controller.amountRangeFilter.value != 'All';

      return PopupMenuButton<void>(
        tooltip: 'Filter by Total Paid (LTV)',
        offset: const Offset(0, 26),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: _PaymentFilterTrigger(
          active: active,
          tooltip: 'Filter by Total Paid (LTV)',
        ),
        itemBuilder: (context) {
          String tempBalance = controller.balanceStatusFilter.value;
          String tempAmount = controller.amountRangeFilter.value;

          return [
            PopupMenuItem<void>(
              enabled: false,
              child: StatefulBuilder(
                builder: (context, setStatePopup) {
                  return GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPopupHeader('Filter by Total Paid (LTV)', active),
                          const SizedBox(height: 8),
                          _buildSectionLabel('BALANCE DUE STATUS'),
                          ...['All', 'Has Balance Due', 'Fully Paid'].map((opt) {
                            return _buildRadioItem(
                              label: opt,
                              isSelected: tempBalance == opt,
                              onTap: () {
                                setStatePopup(() {
                                  tempBalance = opt;
                                });
                              },
                            );
                          }),
                          const SizedBox(height: 8),
                          _buildSectionLabel('MINIMUM PAID AMOUNT'),
                          ...['All', '> ₹10,000', '> ₹25,000', '> ₹50,000', '> ₹1,00,000'].map((opt) {
                            return _buildRadioItem(
                              label: opt == 'All' ? 'All Amounts' : opt,
                              isSelected: tempAmount == opt,
                              onTap: () {
                                setStatePopup(() {
                                  tempAmount = opt;
                                });
                              },
                            );
                          }),
                          const SizedBox(height: 14),
                          _buildPopupActions(
                            context: context,
                            onClear: () {
                              controller.balanceStatusFilter.value = 'All';
                              controller.amountRangeFilter.value = 'All';
                              controller.applyFilters();
                            },
                            onApply: () {
                              controller.balanceStatusFilter.value = tempBalance;
                              controller.amountRangeFilter.value = tempAmount;
                              controller.applyFilters();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ];
        },
      );
    });
  }
}

// ==========================================
// 3. State (SGST Filing) Column Filter
// ==========================================
class PaymentStateFilter extends StatelessWidget {
  final PendingBankTransfersController controller;

  const PaymentStateFilter({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.stateTypeFilter.value != 'All' ||
          controller.stateNameFilter.value != 'All';

      return PopupMenuButton<void>(
        tooltip: 'Filter by State',
        offset: const Offset(0, 26),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: _PaymentFilterTrigger(
          active: active,
          tooltip: 'Filter by State',
        ),
        itemBuilder: (context) {
          String tempType = controller.stateTypeFilter.value;
          String tempStateName = controller.stateNameFilter.value;
          String stateSearch = '';

          return [
            PopupMenuItem<void>(
              enabled: false,
              child: StatefulBuilder(
                builder: (context, setStatePopup) {
                  // Get sorted list of states from gstMasterStateMap
                  final allStates = PendingBankTransfersController.gstMasterStateMap.entries
                      .map((e) => (code: e.key, name: e.value.name))
                      .where((s) => s.code != '25') // skip merged code 25
                      .toList()
                    ..sort((a, b) => a.name.compareTo(b.name));

                  final filteredStates = stateSearch.isEmpty
                      ? allStates
                      : allStates.where((s) =>
                          s.name.toLowerCase().contains(stateSearch.toLowerCase()) ||
                          s.code.contains(stateSearch)).toList();

                  return GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 290,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPopupHeader('Filter by State', active),
                          const SizedBox(height: 8),
                          _buildSectionLabel('GST JURISDICTION'),
                          ...[
                            'All',
                            'Intra-State: MP (9%+9%)',
                            'Inter-State: Outside MP (IGST)',
                            'Unspecified POS'
                          ].map((opt) {
                            return _buildRadioItem(
                              label: opt,
                              isSelected: tempType == opt,
                              onTap: () {
                                setStatePopup(() {
                                  tempType = opt;
                                });
                              },
                            );
                          }),
                          const SizedBox(height: 8),
                          _buildSectionLabel('SPECIFIC STATE'),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search state...',
                              prefixIcon: const Icon(Icons.search, size: 15, color: AppTheme.gray500),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: AppTheme.gray300),
                              ),
                            ),
                            style: const TextStyle(fontSize: 12),
                            onChanged: (val) {
                              setStatePopup(() {
                                stateSearch = val;
                              });
                            },
                          ),
                          const SizedBox(height: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 140),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildRadioItem(
                                    label: 'All States',
                                    isSelected: tempStateName == 'All',
                                    onTap: () {
                                      setStatePopup(() {
                                        tempStateName = 'All';
                                      });
                                    },
                                  ),
                                  ...filteredStates.map((s) {
                                    final label = '${s.name} (${s.code})';
                                    final isSelected = tempStateName == s.name || tempStateName == s.code;
                                    return _buildRadioItem(
                                      label: label,
                                      isSelected: isSelected,
                                      onTap: () {
                                        setStatePopup(() {
                                          tempStateName = s.name;
                                        });
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildPopupActions(
                            context: context,
                            onClear: () {
                              controller.stateTypeFilter.value = 'All';
                              controller.stateNameFilter.value = 'All';
                              controller.applyFilters();
                            },
                            onApply: () {
                              controller.stateTypeFilter.value = tempType;
                              controller.stateNameFilter.value = tempStateName;
                              controller.applyFilters();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ];
        },
      );
    });
  }
}

// ==========================================
// 4. Latest Activity Column Filter
// ==========================================
class PaymentActivityFilter extends StatelessWidget {
  final PendingBankTransfersController controller;

  const PaymentActivityFilter({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.activityFilter.value != 'All' ||
          controller.activityDateFilter.value.isNotEmpty;

      return PopupMenuButton<void>(
        tooltip: 'Filter by Activity',
        offset: const Offset(0, 26),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: _PaymentFilterTrigger(
          active: active,
          tooltip: 'Filter by Activity',
        ),
        itemBuilder: (context) {
          String tempActivity = controller.activityFilter.value;
          final dateCtrl = TextEditingController(text: controller.activityDateFilter.value);

          return [
            PopupMenuItem<void>(
              enabled: false,
              child: StatefulBuilder(
                builder: (context, setStatePopup) {
                  return GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPopupHeader('Filter by Activity', active),
                          const SizedBox(height: 8),
                          _buildSectionLabel('ACTIVITY STATUS / TIMEFRAME'),
                          ...[
                            'All',
                            'Has Pending Slip',
                            'New (< 48 hrs)',
                            'Last 7 Days',
                            'Last 30 Days'
                          ].map((opt) {
                            return _buildRadioItem(
                              label: opt,
                              isSelected: tempActivity == opt,
                              onTap: () {
                                setStatePopup(() {
                                  tempActivity = opt;
                                });
                              },
                            );
                          }),
                          const SizedBox(height: 8),
                          _buildSectionLabel('SPECIFIC ACTIVITY DATE'),
                          TextField(
                            controller: dateCtrl,
                            decoration: InputDecoration(
                              hintText: 'DD/MM/YYYY',
                              prefixIcon: const Icon(
                                Icons.calendar_today,
                                size: 15,
                                color: AppTheme.gray500,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.date_range,
                                  size: 16,
                                  color: AppTheme.primaryBlue,
                                ),
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: now,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    final d = picked.day.toString().padLeft(2, '0');
                                    final m = picked.month.toString().padLeft(2, '0');
                                    final y = picked.year.toString();
                                    setStatePopup(() {
                                      dateCtrl.text = '$d/$m/$y';
                                    });
                                  }
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: AppTheme.gray300),
                              ),
                            ),
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          const SizedBox(height: 14),
                          _buildPopupActions(
                            context: context,
                            onClear: () {
                              controller.activityFilter.value = 'All';
                              controller.activityDateFilter.value = '';
                              controller.applyFilters();
                            },
                            onApply: () {
                              controller.activityFilter.value = tempActivity;
                              controller.activityDateFilter.value = dateCtrl.text.trim();
                              controller.applyFilters();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ];
        },
      );
    });
  }
}
