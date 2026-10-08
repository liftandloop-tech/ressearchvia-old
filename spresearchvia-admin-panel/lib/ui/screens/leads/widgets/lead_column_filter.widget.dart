import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/leads/leads.controller.dart';

class LeadColumnFilter extends StatefulWidget {
  final String columnKey; // 'name', 'mobile', 'stage', 'pool', 'rm', 'location'
  final String columnName;

  const LeadColumnFilter({
    super.key,
    required this.columnKey,
    required this.columnName,
  });

  @override
  State<LeadColumnFilter> createState() => _LeadColumnFilterState();
}

class _LeadColumnFilterState extends State<LeadColumnFilter> {
  final LeadsController controller = Get.find<LeadsController>();

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
    if (widget.columnKey == 'name') {
      _textController.text = controller.filterName.value;
    } else if (widget.columnKey == 'mobile') {
      _textController.text = controller.filterMobile.value;
    } else if (widget.columnKey == 'location') {
      _textController.text = controller.filterLocation.value;
    } else if (widget.columnKey == 'stage') {
      _selectedOption = controller.selectedStage.value.isEmpty
          ? 'All Stages'
          : controller.selectedStage.value;
    } else if (widget.columnKey == 'pool') {
      final poolId = controller.selectedFilterPoolId.value;
      if (poolId.isEmpty) {
        _selectedOption = 'All Pools';
      } else {
        final match = controller.leadPoolsList.firstWhereOrNull((p) => p.id == poolId);
        _selectedOption = match?.name ?? 'All Pools';
      }
    } else if (widget.columnKey == 'rm') {
      final rmId = controller.selectedRMId.value;
      if (rmId.isEmpty) {
        _selectedOption = 'All RMs';
      } else if (rmId == 'unassigned') {
        _selectedOption = 'Unassigned';
      } else if (rmId == 'admin') {
        _selectedOption = 'Admin';
      } else {
        final match = controller.staffList.firstWhereOrNull((s) => s.id == rmId);
        _selectedOption = match != null ? '${match.name} (${match.role})' : 'All RMs';
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _isFiltered {
    if (widget.columnKey == 'name') {
      return controller.filterName.value.isNotEmpty;
    }
    if (widget.columnKey == 'mobile') {
      return controller.filterMobile.value.isNotEmpty;
    }
    if (widget.columnKey == 'location') {
      return controller.filterLocation.value.isNotEmpty;
    }
    if (widget.columnKey == 'stage') {
      return controller.selectedStage.value.isNotEmpty &&
          controller.selectedStage.value != 'All Stages';
    }
    if (widget.columnKey == 'pool') {
      return controller.selectedFilterPoolId.value.isNotEmpty;
    }
    if (widget.columnKey == 'rm') {
      return controller.selectedRMId.value.isNotEmpty;
    }
    return false;
  }

  List<String> _getOptions() {
    if (widget.columnKey == 'stage') {
      const list = [
        'All Stages',
        'New',
        'App Onboarded',
        'Contacted',
        'Interested',
        'Qualified',
        'Demo / Meeting Scheduled',
        'Demo / Meeting Completed',
        'Proposal Sent',
        'Negotiation',
        'Follow-up',
        'Won',
        'Lost',
        'On Hold',
        'Not Interested',
        'Invalid',
      ];
      if (_optionsSearchQuery.isEmpty) return list;
      return list
          .where((opt) => opt.toLowerCase().contains(_optionsSearchQuery.toLowerCase()))
          .toList();
    }
    if (widget.columnKey == 'pool') {
      final list = <String>['All Pools'];
      for (final p in controller.leadPoolsList) {
        if (!list.contains(p.name)) {
          list.add(p.name);
        }
      }
      if (_optionsSearchQuery.isEmpty) return list;
      return list
          .where((opt) => opt.toLowerCase().contains(_optionsSearchQuery.toLowerCase()))
          .toList();
    }
    if (widget.columnKey == 'rm') {
      final list = <String>['All RMs', 'Unassigned', 'Admin'];
      for (final s in controller.staffList) {
        final label = '${s.name} (${s.role})';
        if (!list.contains(label)) {
          list.add(label);
        }
      }
      if (_optionsSearchQuery.isEmpty) return list;
      return list
          .where((opt) => opt.toLowerCase().contains(_optionsSearchQuery.toLowerCase()))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    const knownKeys = {'name', 'mobile', 'stage', 'pool', 'rm', 'location'};

    if (!knownKeys.contains(widget.columnKey)) {
      return _buildPopupMenu(false);
    }

    return Obx(() {
      final active = _isFiltered;
      return _buildPopupMenu(active);
    });
  }

  Widget _buildPopupMenu(bool active) {
    final isTextFilter = widget.columnKey == 'name' ||
        widget.columnKey == 'mobile' ||
        widget.columnKey == 'location';

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
                        if (isTextFilter) ...[
                          TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: widget.columnKey == 'name'
                                  ? 'Search name or email...'
                                  : widget.columnKey == 'mobile'
                                      ? 'Search mobile no...'
                                      : 'Search city or state...',
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
                          if (widget.columnKey == 'rm' || widget.columnKey == 'pool') ...[
                            TextField(
                              onChanged: (val) {
                                setStatePopup(() {
                                  _optionsSearchQuery = val;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: widget.columnKey == 'rm'
                                    ? 'Search RM...'
                                    : 'Search pool...',
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
  }

  void _clearFilter() {
    if (widget.columnKey == 'name') {
      _textController.clear();
      controller.filterName.value = '';
    } else if (widget.columnKey == 'mobile') {
      _textController.clear();
      controller.filterMobile.value = '';
    } else if (widget.columnKey == 'location') {
      _textController.clear();
      controller.filterLocation.value = '';
    } else if (widget.columnKey == 'stage') {
      _selectedOption = 'All Stages';
      controller.selectedStage.value = '';
    } else if (widget.columnKey == 'pool') {
      _selectedOption = 'All Pools';
      controller.selectedFilterPoolId.value = '';
    } else if (widget.columnKey == 'rm') {
      _selectedOption = 'All RMs';
      controller.selectedRMId.value = '';
    }
    controller.currentPage.value = 1;
    controller.fetchLeads();
  }

  void _applyFilter() {
    if (widget.columnKey == 'name') {
      controller.filterName.value = _textController.text.trim();
    } else if (widget.columnKey == 'mobile') {
      controller.filterMobile.value = _textController.text.trim();
    } else if (widget.columnKey == 'location') {
      controller.filterLocation.value = _textController.text.trim();
    } else if (widget.columnKey == 'stage') {
      controller.selectedStage.value =
          _selectedOption == 'All Stages' ? '' : _selectedOption;
    } else if (widget.columnKey == 'pool') {
      if (_selectedOption == 'All Pools') {
        controller.selectedFilterPoolId.value = '';
      } else {
        final match = controller.leadPoolsList.firstWhereOrNull((p) => p.name == _selectedOption);
        controller.selectedFilterPoolId.value = match?.id ?? '';
      }
    } else if (widget.columnKey == 'rm') {
      if (_selectedOption == 'All RMs') {
        controller.selectedRMId.value = '';
      } else if (_selectedOption == 'Unassigned') {
        controller.selectedRMId.value = 'unassigned';
      } else if (_selectedOption == 'Admin') {
        controller.selectedRMId.value = 'admin';
      } else {
        final match = controller.staffList.firstWhereOrNull(
          (s) => '${s.name} (${s.role})' == _selectedOption,
        );
        controller.selectedRMId.value = match?.id ?? '';
      }
    }
    controller.currentPage.value = 1;
    controller.fetchLeads();
  }
}
