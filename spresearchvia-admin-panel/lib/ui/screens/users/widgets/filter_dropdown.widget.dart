import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';

class FilterDropdown extends StatelessWidget {
  final String label;
  final RxString value;
  final List<String> items;
  final Function(String?) onChanged;
  final bool isSearchable;

  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isSearchable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => GestureDetector(
            onTap: isSearchable ? () => _showSearchDialog(context) : null,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.gray300),
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
              ),
              child: isSearchable
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            value.value,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: AppTheme.gray600,
                        ),
                      ],
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: items.contains(value.value) ? value.value : null,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: AppTheme.gray600,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        items: items
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: onChanged,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();
    final filteredItems = items.obs;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select $label'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width / 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (query) {
                    filteredItems.value = items
                        .where(
                          (item) =>
                              item.toLowerCase().contains(query.toLowerCase()),
                        )
                        .toList();
                  },
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Obx(
                    () => ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return ListTile(
                          title: Text(item),
                          onTap: () {
                            onChanged(item);
                            Navigator.pop(context);
                          },
                          selected: item == value.value,
                          selectedColor: AppTheme.primary,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
