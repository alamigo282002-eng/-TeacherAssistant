import 'package:flutter/material.dart';

class DotGridPatternPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double radius;

  const DotGridPatternPainter({
    this.dotColor = const Color(0x1FFFFFFF),
    this.spacing = 16.0,
    this.radius = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPatternPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.radius != radius;
  }
}

class DotGridSurface extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final BorderRadius? borderRadius;
  final Color dotColor;
  final double spacing;
  final double dotRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;

  const DotGridSurface({
    super.key,
    required this.child,
    this.gradient = const LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF022B22), Color(0xFF275D46)],
    ),
    this.borderRadius,
    this.dotColor = const Color(0x1AFFFFFF),
    this.spacing = 15.0,
    this.dotRadius = 1.2,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        border: border,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: CustomPaint(
          painter: DotGridPatternPainter(
            dotColor: dotColor,
            spacing: spacing,
            radius: dotRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}
