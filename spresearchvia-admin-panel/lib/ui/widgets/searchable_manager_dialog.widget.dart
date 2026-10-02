import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import '../../models/staff.model.dart';

class SearchableManagerDialog extends StatefulWidget {
  final String clientName;
  final String? currentManagerId;
  final List<StaffModel> staffList;
  final Function(String staffId, String staffName) onSelected;
  final VoidCallback? onUnassign;

  const SearchableManagerDialog({
    super.key,
    required this.clientName,
    this.currentManagerId,
    required this.staffList,
    required this.onSelected,
    this.onUnassign,
  });

  @override
  State<SearchableManagerDialog> createState() => _SearchableManagerDialogState();
}

class _SearchableManagerDialogState extends State<SearchableManagerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _filter.trim().toLowerCase();
    final filtered = widget.staffList.where((staff) {
      if (query.isEmpty) return true;
      final name = staff.name.toLowerCase();
      final dept = staff.department.toLowerCase();
      final email = staff.email.toLowerCase();
      final id = staff.staffId.toLowerCase();
      return name.contains(query) || dept.contains(query) || email.contains(query) || id.contains(query);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SelectionArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assign Manager',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select a relationship manager for ${widget.clientName}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search manager by name, department, email...',
                  hintStyle: TextStyle(fontSize: 12.5, color: AppTheme.gray400),
                  prefixIcon: const Icon(Icons.search, size: 19, color: Color(0xFF64748B)),
                  suffixIcon: _filter.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _filter = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                  ),
                ),
                onChanged: (val) => setState(() => _filter = val),
              ),
            ),

            const SizedBox(height: 8),

            // List of managers
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_outlined, size: 40, color: AppTheme.gray400),
                          const SizedBox(height: 8),
                          Text(
                            'No managers match "$_filter"',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: filtered.length + (widget.onUnassign != null ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        if (widget.onUnassign != null && index == 0) {
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFF1F5F9),
                              radius: 16,
                              child: Icon(Icons.person_remove_outlined, size: 16, color: AppTheme.gray500),
                            ),
                            title: const Text('Unassigned', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onUnassign!();
                            },
                          );
                        }

                        final actualIndex = widget.onUnassign != null ? index - 1 : index;
                        final staff = filtered[actualIndex];
                        final isSelected = widget.currentManagerId != null &&
                            (widget.currentManagerId == staff.id || widget.currentManagerId == staff.name);

                        return ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          tileColor: isSelected ? const Color(0xFFEFF6FF) : null,
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
                            radius: 17,
                            child: Text(
                              staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  staff.name,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (staff.department.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    staff.department,
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            staff.email.isNotEmpty ? staff.email : (staff.staffId.isNotEmpty ? staff.staffId : 'Staff Member'),
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, size: 19, color: AppTheme.primaryBlue)
                              : null,
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onSelected(staff.id, staff.name);
                          },
                        );
                      },
                    ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} staff member${filtered.length == 1 ? '' : 's'} available',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.gray500),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
