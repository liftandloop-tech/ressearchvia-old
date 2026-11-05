import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/recruitment/applicants_list.controller.dart';

class ApplicantTableHeaderCell extends StatelessWidget {
  final String text;
  final Widget? filterWidget;

  const ApplicantTableHeaderCell({
    super.key,
    required this.text,
    this.filterWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (filterWidget != null) ...[
          const SizedBox(width: 4),
          filterWidget!,
        ],
      ],
    );
  }
}

class ApplicantColumnFilter extends StatefulWidget {
  final String columnKey; // 'candidate', 'role', 'contact', 'status', 'stage', 'staff'
  final String columnName;

  const ApplicantColumnFilter({
    super.key,
    required this.columnKey,
    required this.columnName,
  });

  @override
  State<ApplicantColumnFilter> createState() => _ApplicantColumnFilterState();
}

class _ApplicantColumnFilterState extends State<ApplicantColumnFilter> {
  final ApplicantsListController controller = Get.find<ApplicantsListController>();
  late final TextEditingController _textController;
  final List<String> _selectedOptions = [];
  String _optionsSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _initValues();
  }

  void _initValues() {
    if (widget.columnKey == 'candidate') {
      _textController.text = controller.filterCandidate.value;
    } else if (widget.columnKey == 'contact') {
      _textController.text = controller.filterContact.value;
    } else if (widget.columnKey == 'role') {
      _selectedOptions.clear();
      _selectedOptions.addAll(controller.filterRole);
    } else if (widget.columnKey == 'status') {
      _selectedOptions.clear();
      _selectedOptions.addAll(controller.filterStatus);
    } else if (widget.columnKey == 'stage') {
      _selectedOptions.clear();
      _selectedOptions.addAll(controller.filterStage);
    } else if (widget.columnKey == 'staff') {
      _selectedOptions.clear();
      _selectedOptions.addAll(controller.filterStaff);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _isFiltered {
    if (widget.columnKey == 'candidate') return controller.filterCandidate.value.trim().isNotEmpty;
    if (widget.columnKey == 'contact') return controller.filterContact.value.trim().isNotEmpty;
    if (widget.columnKey == 'role') return controller.filterRole.isNotEmpty;
    if (widget.columnKey == 'status') return controller.filterStatus.isNotEmpty;
    if (widget.columnKey == 'stage') return controller.filterStage.isNotEmpty;
    if (widget.columnKey == 'staff') return controller.filterStaff.isNotEmpty;
    return false;
  }

  List<String> _getOptions() {
    List<String> raw;
    if (widget.columnKey == 'role') {
      raw = controller.availableRoleFilterOptions;
    } else if (widget.columnKey == 'status') {
      raw = controller.availableStatusFilterOptions;
    } else if (widget.columnKey == 'stage') {
      raw = controller.availableStageFilterOptions;
    } else if (widget.columnKey == 'staff') {
      raw = controller.availableStaffFilterOptions;
    } else {
      raw = [];
    }

    if (_optionsSearchQuery.isEmpty) return raw;
    final query = _optionsSearchQuery.toLowerCase();
    return raw.where((opt) => opt.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = _isFiltered;
      final isText = widget.columnKey == 'candidate' || widget.columnKey == 'contact';

      return PopupMenuButton<void>(
        icon: Icon(
          Icons.filter_alt,
          size: 14,
          color: active ? AppTheme.primaryBlue : const Color(0xFF94A3B8),
        ),
        tooltip: 'Filter by ${widget.columnName}',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        offset: const Offset(0, 24),
        itemBuilder: (context) {
          _initValues();
          return [
            PopupMenuItem<void>(
              enabled: false,
              child: StatefulBuilder(
                builder: (context, setStatePopup) {
                  return GestureDetector(
                    onTap: () {}, // Prevent taps inside dialog from closing popup
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.filter_list_rounded, size: 16, color: AppTheme.primaryBlue),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Filter by ${widget.columnName}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (isText) ...[
                            // Text Search Filter
                            TextField(
                              controller: _textController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search ${widget.columnName}...',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                              ),
                              style: const TextStyle(fontSize: 12.5),
                              onSubmitted: (_) {
                                _applyFilter();
                                Navigator.pop(context);
                              },
                            ),
                          ] else ...[
                            // Search within options
                            TextField(
                              onChanged: (val) {
                                setStatePopup(() {
                                  _optionsSearchQuery = val;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search options...',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                              ),
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            const SizedBox(height: 8),

                            // Option Checklist
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 180),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: _getOptions().map((opt) {
                                    final isChecked = _selectedOptions.contains(opt);
                                    return CheckboxListTile(
                                      title: Text(
                                        opt,
                                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                                      ),
                                      value: isChecked,
                                      controlAffinity: ListTileControlAffinity.leading,
                                      dense: true,
                                      activeColor: AppTheme.primaryBlue,
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

                          const SizedBox(height: 14),

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setStatePopup(() {
                                    if (isText) {
                                      _textController.clear();
                                    } else {
                                      _selectedOptions.clear();
                                    }
                                  });
                                  _clearFilter();
                                  Navigator.pop(context);
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                                ),
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: const Text('Cancel', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton(
                                    onPressed: () {
                                      _applyFilter();
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ],
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
    if (widget.columnKey == 'candidate') {
      controller.filterCandidate.value = _textController.text.trim();
    } else if (widget.columnKey == 'contact') {
      controller.filterContact.value = _textController.text.trim();
    } else if (widget.columnKey == 'role') {
      controller.filterRole.assignAll(_selectedOptions);
    } else if (widget.columnKey == 'status') {
      controller.filterStatus.assignAll(_selectedOptions);
    } else if (widget.columnKey == 'stage') {
      controller.filterStage.assignAll(_selectedOptions);
    } else if (widget.columnKey == 'staff') {
      controller.filterStaff.assignAll(_selectedOptions);
    }
  }

  void _clearFilter() {
    if (widget.columnKey == 'candidate') {
      controller.filterCandidate.value = '';
    } else if (widget.columnKey == 'contact') {
      controller.filterContact.value = '';
    } else if (widget.columnKey == 'role') {
      controller.filterRole.clear();
    } else if (widget.columnKey == 'status') {
      controller.filterStatus.clear();
    } else if (widget.columnKey == 'stage') {
      controller.filterStage.clear();
    } else if (widget.columnKey == 'staff') {
      controller.filterStaff.clear();
    }
  }
}

