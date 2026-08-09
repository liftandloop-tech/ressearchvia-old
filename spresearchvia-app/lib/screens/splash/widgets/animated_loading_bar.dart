import 'package:flutter/material.dart';

class AnimatedLoadingBar extends StatelessWidget {
  final AnimationController controller;

  const AnimatedLoadingBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          height: 4,
          width: double.infinity,
          color: const Color(0xffE5E7EB),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: controller.value,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff2C7F38), Color(0xff34A853)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
