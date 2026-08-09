import 'package:flutter/material.dart';

class ConfettiParticle {
  double x;
  double y;
  final Color color;
  double rotation;
  final double rotationSpeed;
  final double size;
  final double velocityX;
  final double velocityY;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.velocityX,
    required this.velocityY,
  });
}
