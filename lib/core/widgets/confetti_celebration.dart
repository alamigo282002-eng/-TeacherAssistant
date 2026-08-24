import 'dart:math';
import 'package:flutter/material.dart';

/// ويدجت احتفالية الكونفيتي عند إتمام تحضير جميع الطلاب أو المجموعات
class ConfettiCelebrationOverlay extends StatefulWidget {
  final VoidCallback? onFinished;

  const ConfettiCelebrationOverlay({super.key, this.onFinished});

  static void show(BuildContext context) {
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => ConfettiCelebrationOverlay(
        onFinished: () {
          entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  State<ConfettiCelebrationOverlay> createState() => _ConfettiCelebrationOverlayState();
}

class _ConfettiCelebrationOverlayState extends State<ConfettiCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _rnd = Random();

  final List<Color> _colors = const [
    Color(0xFF0E8A6D),
    Color(0xFF38EAA0),
    Color(0xFFD97706),
    Color(0xFFFBBF24),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    for (int i = 0; i < 75; i++) {
      _particles.add(_ConfettiParticle(
        x: _rnd.nextDouble(),
        y: -0.1 - _rnd.nextDouble() * 0.3,
        vx: (_rnd.nextDouble() - 0.5) * 0.6,
        vy: 0.4 + _rnd.nextDouble() * 0.7,
        size: 6 + _rnd.nextDouble() * 8,
        color: _colors[_rnd.nextInt(_colors.length)],
        rotation: _rnd.nextDouble() * 2 * pi,
        rotationSpeed: (_rnd.nextDouble() - 0.5) * 8,
        isCircle: _rnd.nextBool(),
      ));
    }

    _controller.forward().then((_) {
      if (mounted) {
        widget.onFinished?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: progress,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
  final bool isCircle;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final opacity = progress > 0.8 ? (1.0 - (progress - 0.8) / 0.2).clamp(0.0, 1.0) : 1.0;

    for (final p in particles) {
      final curX = (p.x + p.vx * progress) * size.width;
      final curY = (p.y + p.vy * progress * 1.5 + 0.5 * 1.2 * progress * progress) * size.height;
      final curRotation = p.rotation + p.rotationSpeed * progress;

      if (curY > size.height + 20) continue;

      paint.color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(curX, curY);
      canvas.rotate(curRotation);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
