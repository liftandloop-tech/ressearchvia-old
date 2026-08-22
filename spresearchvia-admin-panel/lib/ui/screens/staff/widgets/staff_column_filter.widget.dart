import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/staff/staff.controller.dart';

class StaffColumnFilter extends StatefulWidget {
  final String columnKey; // 'name', 'mobile', 'email', 'role', 'status'
  final String columnName;

  const StaffColumnFilter({
    super.key,
    required this.columnKey,
    required this.columnName,
  });

  @override
  State<StaffColumnFilter> createState() => _StaffColumnFilterState();
}

class _StaffColumnFilterState extends State<StaffColumnFilter> {
  final StaffController controller = Get.find<StaffController>();
  late final TextEditingController _searchController;
  final List<String> _selectedOptions = [];
  String _optionsSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initValues();
  }

  void _initValues() {
    if (widget.columnKey == 'name') {
      _searchController.text = controller.filterName.value;
    } else if (widget.columnKey == 'mobile') {
      _searchController.text = controller.filterMobile.value;
    } else if (widget.columnKey == 'email') {
      _searchController.text = controller.filterEmail.value;
    } else if (widget.columnKey == 'role') {
      _selectedOptions.clear();
      _selectedOptions.addAll(controller.filterSelectedRoles);
    } else if (widget.columnKey == 'status') {
      _selectedOptions.clear();
      _selectedOptions.addAll(controller.filterSelectedStatuses);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isFiltered {
    if (widget.columnKey == 'name') return controller.filterName.value.isNotEmpty;
    if (widget.columnKey == 'mobile') return controller.filterMobile.value.isNotEmpty;
    if (widget.columnKey == 'email') return controller.filterEmail.value.isNotEmpty;
    if (widget.columnKey == 'role') return controller.filterSelectedRoles.isNotEmpty;
    if (widget.columnKey == 'status') return controller.filterSelectedStatuses.isNotEmpty;
    return false;
  }

  List<String> _getOptions() {
    if (widget.columnKey == 'role') {
      // Exclude 'All' from options inside selection list
      final allRoles = controller.availableRolesFilterOptions.where((r) => r != 'All').toList();
      if (_optionsSearchQuery.isEmpty) return allRoles;
      return allRoles.where((r) => r.toLowerCase().contains(_optionsSearchQuery.toLowerCase())).toList();
    }
    if (widget.columnKey == 'status') {
      final allStatuses = ['Active', 'Inactive'];
      if (_optionsSearchQuery.isEmpty) return allStatuses;
      return allStatuses.where((s) => s.toLowerCase().contains(_optionsSearchQuery.toLowerCase())).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isTextFilter = widget.columnKey == 'name' || widget.columnKey == 'mobile' || widget.columnKey == 'email';

    return Obx(() {
      // Re-trigger visual highlight if controller state changes externally (e.g. on clear all)
      final activeFilter = _isFiltered;

      return PopupMenuButton<void>(
        icon: Icon(
          Icons.filter_alt,
          size: 14,
          color: activeFilter ? AppTheme.primaryBlue : AppTheme.gray400,
        ),
        tooltip: 'Filter by ${widget.columnName}',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        offset: const Offset(0, 24),
        itemBuilder: (context) {
          // Re-initialize active values whenever the popup opens
          _initValues();
          return [
            PopupMenuItem<void>(
              enabled: false,
              child: StatefulBuilder(
                builder: (context, setStatePopup) {
                  return GestureDetector(
                    onTap: () {}, // Prevent taps from closing menu
                    child: Container(
                      width: 250,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Filter by ${widget.columnName}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isTextFilter) ...[
                            // Text Input Search
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search ${widget.columnName}...',
                                prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.gray400),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: AppTheme.gray300),
                                ),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ] else ...[
                            // Options List with Search Bar
                            TextField(
                              onChanged: (val) {
                                setStatePopup(() {
                                  _optionsSearchQuery = val;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search options...',
                                prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.gray400),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: AppTheme.gray300),
                                ),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 150),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: _getOptions().map((opt) {
                                    final isChecked = _selectedOptions.contains(opt);
                                    return CheckboxListTile(
                                      title: Text(opt, style: const TextStyle(fontSize: 13)),
                                      value: isChecked,
                                      controlAffinity: ListTileControlAffinity.leading,
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (val) {
                                        setStatePopup(() {
                                          if (val == true) {
                                            _selectedOptions.add(opt);
                                          } else {
                                            _selectedOptions.remove(opt);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  // Clear filter
                                  setStatePopup(() {
                                    if (isTextFilter) {
                                      _searchController.clear();
                                    } else {
                                      _selectedOptions.clear();
                                    }
                                  });
                                  _applyFilter();
                                  Navigator.pop(context);
                                },
                                child: const Text('Clear', style: TextStyle(fontSize: 12, color: AppTheme.errorRed)),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text('Apply', style: TextStyle(fontSize: 12)),
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

  void _applyFilter() {
    if (widget.columnKey == 'name') {
      controller.filterName.value = _searchController.text.trim();
    } else if (widget.columnKey == 'mobile') {
      controller.filterMobile.value = _searchController.text.trim();
    } else if (widget.columnKey == 'email') {
      controller.filterEmail.value = _searchController.text.trim();
    } else if (widget.columnKey == 'role') {
      controller.filterSelectedRoles.assignAll(_selectedOptions);
    } else if (widget.columnKey == 'status') {
      controller.filterSelectedStatuses.assignAll(_selectedOptions);
    }
    controller.currentPage.value = 1;
  }
}
