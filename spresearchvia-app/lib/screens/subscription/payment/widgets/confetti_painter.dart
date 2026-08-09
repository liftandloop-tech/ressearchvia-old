import 'package:flutter/material.dart';
import 'dart:math';
import 'confetti_particle.dart';

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      double currentY = particle.y + (particle.velocityY * progress);
      double currentX = particle.x + (particle.velocityX * progress * 0.5);
      double currentRotation =
          particle.rotation + (particle.rotationSpeed * progress * 2 * pi);

      double fadeStart = 0.85;
      double opacity = 1.0;

      if (progress > fadeStart) {
        opacity = 1.0 - ((progress - fadeStart) / (1.0 - fadeStart));
      }

      if (opacity < 0) opacity = 0;

      if (currentY <= 1.1 && opacity > 0) {
        double actualX = currentX * size.width;
        double actualY = currentY * size.height;

        canvas.save();
        canvas.translate(actualX, actualY);
        canvas.rotate(currentRotation);

        final paint = Paint()
          ..color = particle.color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 1.5,
          ),
          paint,
        );

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
