import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user.controller.dart';
import 'package:spresearch_web/controllers/users/user_management.controller.dart';

class UserColumnFilter extends StatefulWidget {
  final String columnKey; // 'createdAt', 'name', 'mobile', 'kycStatus', 'subscription', 'manager'
  final String columnName;

  const UserColumnFilter({
    super.key,
    required this.columnKey,
    required this.columnName,
  });

  @override
  State<UserColumnFilter> createState() => _UserColumnFilterState();
}

class _UserColumnFilterState extends State<UserColumnFilter> {
  final UserController controller = Get.find<UserController>();
  final UserManagementController userManagementController =
      Get.find<UserManagementController>();

  late final TextEditingController _textController;
  String _selectedOption = '';
  String _optionsSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _initValues();
  }

  void _initValues() {
    if (widget.columnKey == 'createdAt') {
      _textController.text = controller.registrationDateFilter.value;
    } else if (widget.columnKey == 'name') {
      _textController.text = controller.nameFilter.value;
    } else if (widget.columnKey == 'mobile') {
      _textController.text = controller.mobileFilter.value;
    } else if (widget.columnKey == 'kycStatus') {
      _selectedOption = controller.kycStatusFilter.value;
    } else if (widget.columnKey == 'subscription') {
      _selectedOption = controller.subscriptionStatusFilter.value;
    } else if (widget.columnKey == 'manager') {
      _selectedOption = controller.managerFilter.value;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _isFiltered {
    if (widget.columnKey == 'createdAt') {
      return controller.registrationDateFilter.value.isNotEmpty;
    }
    if (widget.columnKey == 'name') {
      return controller.nameFilter.value.isNotEmpty;
    }
    if (widget.columnKey == 'mobile') {
      return controller.mobileFilter.value.isNotEmpty;
    }
    if (widget.columnKey == 'kycStatus') {
      return controller.kycStatusFilter.value != 'All' &&
          controller.kycStatusFilter.value.isNotEmpty;
    }
    if (widget.columnKey == 'subscription') {
      return controller.subscriptionStatusFilter.value != 'All Statuses';
    }
    if (widget.columnKey == 'manager') {
      return controller.managerFilter.value != 'All Managers';
    }
    return false;
  }

  List<String> _getOptions() {
    if (widget.columnKey == 'kycStatus') {
      return ['All', 'NOT_STARTED', 'IN_PROGRESS', 'VERIFIED', 'REJECTED'];
    }
    if (widget.columnKey == 'subscription') {
      return ['All Statuses', 'Active', 'Expired', 'Trial'];
    }
    if (widget.columnKey == 'manager') {
      final list = <String>['All Managers', 'Unassigned'];
      for (var m in userManagementController.managers) {
        if (!list.contains(m.name)) {
          list.add(m.name);
        }
      }
      if (_optionsSearchQuery.isEmpty) return list;
      return list
          .where(
            (opt) => opt.toLowerCase().contains(_optionsSearchQuery.toLowerCase()),
          )
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isTextFilter = widget.columnKey == 'name' || widget.columnKey == 'mobile';
    final isDateFilter = widget.columnKey == 'createdAt';

    return Obx(() {
      final active = _isFiltered;

      return PopupMenuButton<void>(
        tooltip: 'Filter by ${widget.columnName}',
        offset: const Offset(0, 24),
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Icon(
            Icons.filter_alt,
            size: 13,
            color: active ? AppTheme.primaryBlue : AppTheme.gray400,
          ),
        ),
        itemBuilder: (context) {
          _initValues();
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Filter by ${widget.columnName}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (active)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x1A2563EB),
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
                          ),
                          const SizedBox(height: 12),
                          if (isDateFilter) ...[
                            TextField(
                              controller: _textController,
                              decoration: InputDecoration(
                                hintText: 'DD/MM/YYYY',
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppTheme.gray500,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.date_range,
                                    size: 18,
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
                                      final d = picked.day
                                          .toString()
                                          .padLeft(2, '0');
                                      final m = picked.month
                                          .toString()
                                          .padLeft(2, '0');
                                      final y = picked.year.toString();
                                      setStatePopup(() {
                                        _textController.text = '$d/$m/$y';
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
                                  borderSide: BorderSide(
                                    color: AppTheme.gray300,
                                  ),
                                ),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ] else if (isTextFilter) ...[
                            TextField(
                              controller: _textController,
                              decoration: InputDecoration(
                                hintText: 'Search ${widget.columnName}...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 16,
                                  color: AppTheme.gray500,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: AppTheme.gray300,
                                  ),
                                ),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ] else ...[
                            if (widget.columnKey == 'manager') ...[
                              TextField(
                                onChanged: (val) {
                                  setStatePopup(() {
                                    _optionsSearchQuery = val;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search manager...',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 16,
                                    color: AppTheme.gray500,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: AppTheme.gray300,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                            ],
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 180),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: _getOptions().map((opt) {
                                    final isSelected = _selectedOption == opt;
                                    return InkWell(
                                      onTap: () {
                                        setStatePopup(() {
                                          _selectedOption = opt;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected
                                                  ? Icons.radio_button_checked
                                                  : Icons.radio_button_off,
                                              size: 16,
                                              color: isSelected
                                                  ? AppTheme.primaryBlue
                                                  : AppTheme.gray400,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                opt,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                  color: isSelected
                                                      ? AppTheme.primaryBlue
                                                      : AppTheme.textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _clearFilter();
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.errorRed,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  _applyFilter();
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text(
                                  'Apply',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
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

  void _clearFilter() {
    if (widget.columnKey == 'createdAt') {
      _textController.clear();
      controller.registrationDateFilter.value = '';
    } else if (widget.columnKey == 'name') {
      _textController.clear();
      controller.nameFilter.value = '';
    } else if (widget.columnKey == 'mobile') {
      _textController.clear();
      controller.mobileFilter.value = '';
    } else if (widget.columnKey == 'kycStatus') {
      _selectedOption = 'All';
      controller.kycStatusFilter.value = 'All';
    } else if (widget.columnKey == 'subscription') {
      _selectedOption = 'All Statuses';
      controller.subscriptionStatusFilter.value = 'All Statuses';
    } else if (widget.columnKey == 'manager') {
      _selectedOption = 'All Managers';
      controller.managerFilter.value = 'All Managers';
    }
    controller.fetchFilteredUsers(page: 1);
  }

  void _applyFilter() {
    if (widget.columnKey == 'createdAt') {
      controller.registrationDateFilter.value = _textController.text.trim();
    } else if (widget.columnKey == 'name') {
      controller.nameFilter.value = _textController.text.trim();
    } else if (widget.columnKey == 'mobile') {
      controller.mobileFilter.value = _textController.text.trim();
    } else if (widget.columnKey == 'kycStatus') {
      controller.kycStatusFilter.value = _selectedOption;
    } else if (widget.columnKey == 'subscription') {
      controller.subscriptionStatusFilter.value = _selectedOption;
    } else if (widget.columnKey == 'manager') {
      controller.managerFilter.value = _selectedOption;
    }
    controller.fetchFilteredUsers(page: 1);
  }
}
