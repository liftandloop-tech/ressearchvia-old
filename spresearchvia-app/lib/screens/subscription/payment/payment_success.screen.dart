import 'package:flutter/material.dart';
import 'dart:math';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../widgets/button.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;
  final List<ConfettiParticle> _confettiParticles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    for (int i = 0; i < 50; i++) {
      _confettiParticles.add(
        ConfettiParticle(
          x: _random.nextDouble(),
          y: -0.1 - (_random.nextDouble() * 0.2),
          color: _getRandomColor(),
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 4,
          size: _random.nextDouble() * 8 + 4,
          velocityX: (_random.nextDouble() - 0.5) * 0.3,
          velocityY: _random.nextDouble() * 0.5 + 0.5,
        ),
      );
    }

    _confettiController.forward();
  }

  Color _getRandomColor() {
    List<Color> colors = [
      const Color(0xff2563EB),
      const Color(0xff8DB4A0),
      const Color(0xffF59E0B),
      const Color(0xffEF4444),
      const Color(0xff8B5CF6),
      const Color(0xff10B981),
      const Color(0xffEC4899),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> paymentData = Get.arguments ?? {};
    final String? validUntil = paymentData['validUntil'];
    final String? planName = paymentData['planName'];
    final String? amount = paymentData['amount'];
    final String? nextBilling = paymentData['nextBilling'];
    final bool isBankTransfer = paymentData['isBankTransfer'] ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isBankTransfer ? const Color(0xff8DB4A0) : const Color(0xff8DB4A0),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 4),
                          blurRadius: 20,
                          color: const Color(0xff8DB4A0).withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 40),

                  Text(
                    isBankTransfer ? 'Order\nPlaced!' : 'Payment\nSuccessful!',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1F2937),
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  isBankTransfer 
                  ? const Text(
                      'Your bank transfer request has been received.\nAdmin will verify and activate your plan shortly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff6B7280),
                        height: 1.5,
                      ),
                    )
                  : RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff6B7280),
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Your subscription is valid until\n',
                        ),
                        if (validUntil != null)
                          TextSpan(
                            text: validUntil,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xff2563EB),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xffF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        if (planName != null)
                          DetailRow(label: 'Plan', value: planName),
                        if (planName != null) const SizedBox(height: 16),
                        if (amount != null)
                          DetailRow(label: 'Amount', value: amount),
                        if (amount != null) const SizedBox(height: 16),
                        if (nextBilling != null)
                          DetailRow(label: 'Next billing', value: nextBilling),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Button(
                    title: 'Go To Dashboard',
                    buttonType: ButtonType.blue,
                    onTap: () {

                      Get.offAllNamed(AppRoutes.tabs);
                    },
                  ),
                  const SizedBox(height: 15),
                  Button(
                    title: 'View Receipt',
                    buttonType: ButtonType.blueBorder,
                    onTap: () {
                      Get.toNamed(AppRoutes.receipt);
                    },
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {},
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff6B7280),
                        ),
                        children: [
                          TextSpan(text: 'Need help? '),
                          TextSpan(
                            text: 'Contact Support',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xff2563EB),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_confettiController.value < 1.0)
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return IgnorePointer(
                  child: CustomPaint(
                    painter: ConfettiPainter(
                      particles: _confettiParticles,
                      progress: _confettiController.value,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

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

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xff6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xff1F2937),
          ),
        ),
      ],
    );
  }
}
