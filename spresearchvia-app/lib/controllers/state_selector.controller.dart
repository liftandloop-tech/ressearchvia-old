import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: closeDropdown,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 4,
              width: size.width,
              child: CompositedTransformFollower(
                link: layerLink,
                showWhenUnlinked: false,
                child: Material(
                  elevation: 6.0,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 220),
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
