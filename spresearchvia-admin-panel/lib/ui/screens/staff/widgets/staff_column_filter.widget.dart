import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/staff/staff.controller.dart';

class StaffColumnFilter extends StatefulWidget {
  final String columnKey; // 'name', 'mobile', 'email', 'role', 'branch', 'hr', 'reportingTo', 'status'
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
    _optionsSearchQuery = '';
    if (widget.columnKey == 'name') {
      _searchController.text = controller.filterName.value;
    } else if (widget.columnKey == 'mobile') {
      _searchController.text = controller.filterMobile.value;
    } else if (widget.columnKey == 'email') {
      _searchController.text = controller.filterEmail.value;
    } else if (widget.columnKey == 'role') {
      _selectedOptions.clear();
      _selectedOptions.addAll(controller.filterSelectedRoles);
    } else if (widget.columnKey == 'branch') {
      _selectedOptions.clear();
      _selectedOptions.addAll(controller.filterSelectedBranches);
    } else if (widget.columnKey == 'hr') {
      _selectedOptions.clear();
      _selectedOptions.addAll(controller.filterSelectedHRs);
    } else if (widget.columnKey == 'reportingTo') {
      _selectedOptions.clear();
      _selectedOptions.addAll(controller.filterSelectedReportingTo);
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
    if (widget.columnKey == 'branch') return controller.filterSelectedBranches.isNotEmpty;
    if (widget.columnKey == 'hr') return controller.filterSelectedHRs.isNotEmpty;
    if (widget.columnKey == 'reportingTo') return controller.filterSelectedReportingTo.isNotEmpty;
    if (widget.columnKey == 'status') return controller.filterSelectedStatuses.isNotEmpty;
    return false;
  }

  List<String> _getOptions() {
    List<String> raw = [];
    if (widget.columnKey == 'role') {
      raw = controller.availableRolesFilterOptions.where((r) => r != 'All').toList();
    } else if (widget.columnKey == 'branch') {
      raw = controller.availableBranchesFilterOptions;
    } else if (widget.columnKey == 'hr') {
      raw = controller.availableHRFilterOptions;
    } else if (widget.columnKey == 'reportingTo') {
      raw = controller.availableReportingToFilterOptions;
    } else if (widget.columnKey == 'status') {
      raw = const ['Active', 'Inactive'];
    }

    if (_optionsSearchQuery.trim().isEmpty) return raw;
    final q = _optionsSearchQuery.trim().toLowerCase();
    return raw.where((opt) => opt.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    const knownKeys = {
      'name',
      'mobile',
      'email',
      'role',
      'branch',
      'hr',
      'reportingTo',
      'status',
    };

    if (!knownKeys.contains(widget.columnKey)) {
      return _buildPopupMenu(false);
    }

    return Obx(() {
      final activeFilter = _isFiltered;
      return _buildPopupMenu(activeFilter);
    });
  }

  Widget _buildPopupMenu(bool activeFilter) {
    final isTextFilter = widget.columnKey == 'name' || widget.columnKey == 'mobile' || widget.columnKey == 'email';

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
        _initValues();
        final scrollController = ScrollController();

        return [
          PopupMenuItem<void>(
            enabled: false,
            child: StatefulBuilder(
              builder: (context, setStatePopup) {
                final options = _getOptions();

                return GestureDetector(
                  onTap: () {}, // Prevent taps from closing menu
                  child: Container(
                    width: 270,
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
                            if (!isTextFilter && options.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  setStatePopup(() {
                                    if (_selectedOptions.length == options.length) {
                                      _selectedOptions.clear();
                                    } else {
                                      _selectedOptions.clear();
                                      _selectedOptions.addAll(options);
                                    }
                                  });
                                },
                                child: Text(
                                  _selectedOptions.length == options.length ? 'Deselect All' : 'Select All',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
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
                          // Options Search Bar
                          TextField(
                            onChanged: (val) {
                              setStatePopup(() {
                                _optionsSearchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search ${widget.columnName.toLowerCase()}...',
                              prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.gray400),
                              suffixIcon: _optionsSearchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 14, color: AppTheme.gray400),
                                      onPressed: () {
                                        setStatePopup(() {
                                          _optionsSearchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
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
                          // Scroller with Visible Scrollbar
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: Scrollbar(
                              controller: scrollController,
                              thumbVisibility: true,
                              child: options.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: Text(
                                          'No matching ${widget.columnName.toLowerCase()} found',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.gray400),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: scrollController,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, idx) {
                                        final opt = options[idx];
                                        final isChecked = _selectedOptions.contains(opt);
                                        return CheckboxListTile(
                                          title: Text(
                                            opt,
                                            style: const TextStyle(fontSize: 12.5),
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                                      },
                                    ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
    } else if (widget.columnKey == 'branch') {
      controller.filterSelectedBranches.assignAll(_selectedOptions);
    } else if (widget.columnKey == 'hr') {
      controller.filterSelectedHRs.assignAll(_selectedOptions);
    } else if (widget.columnKey == 'reportingTo') {
      controller.filterSelectedReportingTo.assignAll(_selectedOptions);
    } else if (widget.columnKey == 'status') {
      controller.filterSelectedStatuses.assignAll(_selectedOptions);
    }
    controller.currentPage.value = 1;
  }
}
