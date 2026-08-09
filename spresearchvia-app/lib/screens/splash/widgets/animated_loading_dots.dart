import 'package:flutter/material.dart';

class AnimatedLoadingDots extends StatelessWidget {
  final AnimationController controller;

  const AnimatedLoadingDots({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (controller.value - delay) % 1.0;
            final opacity = value < 0.5
                ? 1.0 - (value * 0.6)
                : 0.4 + (value * 0.6);

            return Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(
                  0xff2C7F38,
                ).withValues(alpha: opacity.clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
