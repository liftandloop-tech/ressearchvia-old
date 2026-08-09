import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';

class _DropdownController extends GetxController {
  final isOpen = false.obs;
  final LayerLink layerLink = LayerLink();
  OverlayEntry? overlayEntry;

  @override
  void onClose() {
    overlayEntry?.remove();
    super.onClose();
  }

  void toggleDropdown(
    BuildContext context,
    Widget Function(BuildContext) overlayBuilder,
  ) {
    if (isOpen.value) {
      closeDropdown();
    } else {
      openDropdown(context, overlayBuilder);
    }
  }

  void openDropdown(
    BuildContext context,
    Widget Function(BuildContext) overlayBuilder,
  ) {
    overlayEntry = OverlayEntry(builder: overlayBuilder);
    Overlay.of(context).insert(overlayEntry!);
    isOpen.value = true;
  }

  void closeDropdown() {
    overlayEntry?.remove();
    overlayEntry = null;
    isOpen.value = false;
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

  Widget _createOverlayWidget(
    BuildContext context,
    _DropdownController controller,
  ) {
    final responsive = Responsive.of(context);
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: controller.closeDropdown,
      child: Stack(
        children: [
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + responsive.hp(0.5),
            width: size.width,
            child: CompositedTransformFollower(
              link: controller.layerLink,
              showWhenUnlinked: false,
              child: Material(
                elevation: 6.0,
                borderRadius: BorderRadius.circular(responsive.radius(12)),
                child: Container(
                  constraints: BoxConstraints(maxHeight: responsive.hp(30)),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.circular(responsive.radius(12)),
                    border: Border.all(color: AppTheme.borderGrey),
                  ),
                  child: indianStates.isEmpty
                      ? Padding(
                          padding: responsive.padding(all: 16.0),
                          child: Text(
                            'No options',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppTheme.textGrey,
                              fontSize: responsive.sp(14),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: indianStates.length,
                          itemBuilder: (context, index) {
                            final item = indianStates[index];
                            final selected = value == item;
                            return InkWell(
                              onTap: () {
                                onChanged(item);
                                controller.closeDropdown();
                              },
                              child: Container(
                                padding: responsive.padding(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppTheme.backgroundLightBlue
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    responsive.radius(8),
                                  ),
                                ),
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: selected
                                        ? AppTheme.primaryBlue
                                        : AppTheme.textBlack,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: responsive.sp(14),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final controller = Get.put(_DropdownController(), tag: '$label-$hashCode');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: responsive.sp(14),
            color: AppTheme.textBlack,
          ),
        ),
        SizedBox(height: responsive.hp(0.75)),
        CompositedTransformTarget(
          link: controller.layerLink,
          child: GestureDetector(
            onTap: () => controller.toggleDropdown(
              context,
              (ctx) => _createOverlayWidget(context, controller),
            ),
            child: Obx(
              () => Container(
                padding: responsive.padding(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.infoBackground,
                  borderRadius: BorderRadius.circular(responsive.radius(12)),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        value ?? hint ?? 'Select $label',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: value != null
                              ? AppTheme.textBlack
                              : AppTheme.textGrey,
                          fontSize: responsive.sp(16),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      controller.isOpen.value
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppTheme.textGrey,
                      size: responsive.sp(24),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
