import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/state_map.dart' as map_utils;

final List<String> indianStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
];

class StateSelectorController extends GetxController {
  final RxBool isOpen = false.obs;
  final Rxn<String> selectedValue = Rxn<String>();
  OverlayEntry? overlayEntry;

  String? getStateNameFromCode(String? code) {
    return map_utils.getStateNameFromCode(code);
  }

  @override
  void onClose() {
    overlayEntry?.remove();
    super.onClose();
  }

  void toggleDropdown(
    BuildContext context,
    LayerLink layerLink,
    ValueChanged<String?> onChanged,
    String? value,
    String? hint,
    String label,
  ) {
    if (isOpen.value) {
      closeDropdown();
    } else {
      openDropdown(context, layerLink, onChanged, value, hint, label);
    }
  }

  void openDropdown(
    BuildContext context,
    LayerLink layerLink,
    ValueChanged<String?> onChanged,
    String? value,
    String? hint,
    String label,
  ) {
    overlayEntry = _createOverlayEntry(context, layerLink, onChanged, value);
    Overlay.of(context).insert(overlayEntry!);
    isOpen.value = true;
  }

  void closeDropdown() {
    overlayEntry?.remove();
    overlayEntry = null;
    isOpen.value = false;
  }

  OverlayEntry _createOverlayEntry(
    BuildContext context,
    LayerLink layerLink,
    ValueChanged<String?> onChanged,
    String? value,
  ) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Calculate available space
    final double spaceBelow = screenHeight - offset.dy - size.height - keyboardHeight - 20;
    final double spaceAbove = offset.dy - MediaQuery.of(context).padding.top - 20;

    final double defaultMaxHeight = 250.0;
    final bool showAbove = spaceBelow < defaultMaxHeight && spaceAbove > spaceBelow;

    double actualMaxHeight = showAbove
        ? (spaceAbove < defaultMaxHeight ? spaceAbove : defaultMaxHeight)
        : (spaceBelow < defaultMaxHeight ? spaceBelow : defaultMaxHeight);
        
    actualMaxHeight = actualMaxHeight.clamp(50.0, defaultMaxHeight);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: closeDropdown,
        child: Stack(
          children: [
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, showAbove ? -(actualMaxHeight + 4) : size.height + 4),
                child: Material(
                  elevation: 6.0,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: actualMaxHeight),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: indianStates.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No options',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: indianStates.length,
                            itemBuilder: (context, index) {
                              final item = indianStates[index];
                              final selected =
                                  (selectedValue.value ?? value) == item;
                              return InkWell(
                                onTap: () {
                                  selectedValue.value = item;
                                  onChanged(item);
                                  closeDropdown();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.blue.shade50
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: selected
                                          ? Colors.blue
                                          : Colors.black87,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StateSelector extends StatelessWidget {
  StateSelector({
    super.key,
    required this.label,
    this.hint,
    this.value,
    required this.onChanged,
  });

  final String label;
  final String? hint;
  final String? value;
  final ValueChanged<String?> onChanged;

  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      StateSelectorController(),
      tag: label.hashCode.toString(),
    );

    return Obx(() {
      final rawValue = controller.selectedValue.value ?? value;
      final displayValue = controller.getStateNameFromCode(rawValue);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          CompositedTransformTarget(
            link: _layerLink,
            child: GestureDetector(
              onTap: () => controller.toggleDropdown(
                context,
                _layerLink,
                onChanged,
                value,
                hint,
                label,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayValue ?? hint ?? 'Select $label',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: displayValue != null
                              ? Colors.black87
                              : Colors.grey,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      controller.isOpen.value
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
