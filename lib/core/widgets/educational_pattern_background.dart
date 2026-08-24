import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Reusable background widget that renders a rich green gradient
/// (#0D5C5C -> #0D6B6B -> #0D8A7A) overlayed with a subtle educational pattern
/// containing notebooks, pens, books, graduation caps, rulers, and math symbols.
class EducationalPatternBackground extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;

  const EducationalPatternBackground({
    super.key,
    required this.child,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D5C5C), // Green dark
            Color(0xFF0D6B6B), // Green medium
            Color(0xFF0D8A7A), // Green light
          ],
        ),
      ),
      child: CustomPaint(
        painter: const _EducationalPatternPainter(),
        child: useSafeArea ? SafeArea(child: child) : child,
      ),
    );
  }
}

class _EducationalPatternPainter extends CustomPainter {
  const _EducationalPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    // We tile educational doodle elements across a repeating grid
    const double stepX = 110.0;
    const double stepY = 120.0;

    int cols = (size.width / stepX).ceil() + 1;
    int rows = (size.height / stepY).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double x = c * stepX + ((r % 2 == 1) ? stepX / 2 : 0);
        final double y = r * stepY + 20;

        final int itemType = (r * 3 + c * 2) % 7;

        canvas.save();
        canvas.translate(x, y);

        switch (itemType) {
          case 0:
            _drawOpenBook(canvas, paint, fillPaint);
            break;
          case 1:
            _drawNotebook(canvas, paint);
            break;
          case 2:
            _drawPencil(canvas, paint);
            break;
          case 3:
            _drawGraduationCap(canvas, paint, fillPaint);
            break;
          case 4:
            _drawRuler(canvas, paint);
            break;
          case 5:
            _drawAtom(canvas, paint);
            break;
          case 6:
            _drawMathSymbols(canvas, paint);
            break;
        }

        canvas.restore();
      }
    }
  }

  void _drawOpenBook(Canvas canvas, Paint stroke, Paint fill) {
    // Open book doodle
    final path = Path();
    path.moveTo(0, 4);
    path.quadraticBezierTo(-10, -3, -20, 0);
    path.lineTo(-20, 16);
    path.quadraticBezierTo(-10, 13, 0, 19);
    path.quadraticBezierTo(10, 13, 20, 16);
    path.lineTo(20, 0);
    path.quadraticBezierTo(10, -3, 0, 4);
    path.close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    // Spine line
    canvas.drawLine(const Offset(0, 4), const Offset(0, 19), stroke);
    // Page lines
    canvas.drawLine(const Offset(-15, 6), const Offset(-5, 8), stroke);
    canvas.drawLine(const Offset(-15, 10), const Offset(-5, 12), stroke);
    canvas.drawLine(const Offset(5, 8), const Offset(15, 6), stroke);
    canvas.drawLine(const Offset(5, 12), const Offset(15, 10), stroke);
  }

  void _drawNotebook(Canvas canvas, Paint stroke) {
    // Notebook (كراسة) with spiral rings
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-12, -14, 24, 30),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, stroke);

    // Spiral binding rings
    for (double y = -10; y <= 12; y += 5) {
      canvas.drawLine(Offset(-14, y), Offset(-10, y), stroke);
    }
    // Notebook ruled lines
    canvas.drawLine(const Offset(-6, -6), const Offset(8, -6), stroke);
    canvas.drawLine(const Offset(-6, 0), const Offset(8, 0), stroke);
    canvas.drawLine(const Offset(-6, 6), const Offset(8, 6), stroke);
  }

  void _drawPencil(Canvas canvas, Paint stroke) {
    // Slanted pencil doodle (قلم)
    canvas.save();
    canvas.rotate(-math.pi / 4);

    final body = Rect.fromLTWH(-4, -14, 8, 22);
    canvas.drawRect(body, stroke);

    // Pencil tip
    final tip = Path()
      ..moveTo(-4, -14)
      ..lineTo(0, -22)
      ..lineTo(4, -14)
      ..close();
    canvas.drawPath(tip, stroke);

    // Eraser on back
    final eraser = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-4, 8, 8, 4),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(eraser, stroke);

    canvas.restore();
  }

  void _drawGraduationCap(Canvas canvas, Paint stroke, Paint fill) {
    // Graduation cap doodle (طاقية تخرج)
    final rhombus = Path()
      ..moveTo(0, -8)
      ..lineTo(16, 0)
      ..lineTo(0, 8)
      ..lineTo(-16, 0)
      ..close();

    canvas.drawPath(rhombus, fill);
    canvas.drawPath(rhombus, stroke);

    // Skull cap underneath
    final capBase = Path()
      ..moveTo(-8, 3)
      ..quadraticBezierTo(0, 11, 8, 3)
      ..lineTo(7, 8)
      ..quadraticBezierTo(0, 14, -7, 8)
      ..close();
    canvas.drawPath(capBase, stroke);

    // Tassel string & drop
    canvas.drawLine(const Offset(0, 0), const Offset(12, 6), stroke);
    canvas.drawLine(const Offset(12, 6), const Offset(12, 12), stroke);
  }

  void _drawRuler(Canvas canvas, Paint stroke) {
    // Triangular or flat ruler
    canvas.save();
    canvas.rotate(math.pi / 6);

    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-16, -5, 32, 10),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, stroke);

    // Measurement notches
    for (double x = -12; x <= 12; x += 4) {
      final double h = (x == 0 || x == -12 || x == 12) ? -1 : -3;
      canvas.drawLine(Offset(x, -5), Offset(x, h), stroke);
    }

    canvas.restore();
  }

  void _drawAtom(Canvas canvas, Paint stroke) {
    // Atom science symbol
    canvas.drawCircle(Offset.zero, 2.5, stroke);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 26, height: 10),
      stroke,
    );

    canvas.save();
    canvas.rotate(math.pi / 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 26, height: 10),
      stroke,
    );
    canvas.restore();
  }

  void _drawMathSymbols(Canvas canvas, Paint stroke) {
    // + symbol
    canvas.drawLine(const Offset(-8, -6), const Offset(-2, -6), stroke);
    canvas.drawLine(const Offset(-5, -9), const Offset(-5, -3), stroke);

    // √ square root
    final sqrtPath = Path()
      ..moveTo(2, 5)
      ..lineTo(4, 7)
      ..lineTo(7, 0)
      ..lineTo(14, 0);
    canvas.drawPath(sqrtPath, stroke);

    // ÷ division
    canvas.drawLine(const Offset(-8, 6), const Offset(-2, 6), stroke);
    canvas.drawCircle(const Offset(-5, 3), 1, stroke);
    canvas.drawCircle(const Offset(-5, 9), 1, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
