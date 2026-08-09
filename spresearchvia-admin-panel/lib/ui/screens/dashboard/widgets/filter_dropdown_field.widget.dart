import 'package:flutter/material.dart';

class FilterDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? icon;
  final VoidCallback? onTap;

  const FilterDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xff11416B),
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xffE5E7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: onTap != null
                      ? Text(
                          value,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xff11416B),
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: value,
                            isExpanded: true,
                            icon: const SizedBox.shrink(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xff11416B),
                            ),
                            items: items
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: onChanged,
                          ),
                        ),
                ),
                Icon(
                  icon ?? Icons.keyboard_arrow_down,
                  color: const Color(0xff11416B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
