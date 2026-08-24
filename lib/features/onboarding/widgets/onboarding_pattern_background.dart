import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum OnboardingStepType {
  profile,      // 1: Teacher & Profile
  subjects,     // 2: Subjects Selection
  setupMode,    // 3: Quick vs Custom Setup
  themeFont,    // 4: Appearance & Font Scale
  security,     // 5: PIN & Security
  permissions,  // 6: Notifications & Alarms
  community,    // 7: Egypt Teachers Group
  features,     // 8: Features & Ready
}

class OnboardingPatternBackground extends StatelessWidget {
  final OnboardingStepType stepType;
  final bool isDark;
  final Widget child;

  const OnboardingPatternBackground({
    super.key,
    required this.stepType,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkBg : const Color(0xFFF3F7F5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      height: double.infinity,
      color: bgColor,
      child: CustomPaint(
        painter: _StepPatternPainter(
          stepType: stepType,
          isDark: isDark,
        ),
        child: child,
      ),
    );
  }
}

class _StepPatternPainter extends CustomPainter {
  final OnboardingStepType stepType;
  final bool isDark;

  const _StepPatternPainter({
    required this.stepType,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Color patternColor = isDark
        ? const Color(0xFF6EAF90)
        : const Color(0xFF275D46);

    final double strokeAlpha = isDark ? 0.075 : 0.055;
    final double fillAlpha = isDark ? 0.035 : 0.025;

    final strokePaint = Paint()
      ..color = patternColor.withValues(alpha: strokeAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = patternColor.withValues(alpha: fillAlpha)
      ..style = PaintingStyle.fill;

    const double stepX = 110.0;
    const double stepY = 120.0;

    int cols = (size.width / stepX).ceil() + 1;
    int rows = (size.height / stepY).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double x = c * stepX + ((r % 2 == 1) ? stepX / 2 : 0);
        final double y = r * stepY + 15;

        canvas.save();
        canvas.translate(x, y);

        final int itemIndex = (r * 3 + c * 2) % 6;
        _drawThematicItem(canvas, strokePaint, fillPaint, stepType, itemIndex);

        canvas.restore();
      }
    }
  }

  void _drawThematicItem(
    Canvas canvas,
    Paint stroke,
    Paint fill,
    OnboardingStepType type,
    int index,
  ) {
    switch (type) {
      case OnboardingStepType.profile:
        _drawProfileMotif(canvas, stroke, fill, index);
        break;
      case OnboardingStepType.subjects:
        _drawSubjectsMotif(canvas, stroke, fill, index);
        break;
      case OnboardingStepType.setupMode:
        _drawSetupMotif(canvas, stroke, fill, index);
        break;
      case OnboardingStepType.themeFont:
        _drawThemeMotif(canvas, stroke, fill, index);
        break;
      case OnboardingStepType.security:
        _drawSecurityMotif(canvas, stroke, fill, index);
        break;
      case OnboardingStepType.permissions:
        _drawPermissionsMotif(canvas, stroke, fill, index);
        break;
      case OnboardingStepType.community:
        _drawCommunityMotif(canvas, stroke, fill, index);
        break;
      case OnboardingStepType.features:
        _drawFeaturesMotif(canvas, stroke, fill, index);
        break;
    }
  }

  // 1. Profile / Teacher Motifs
  void _drawProfileMotif(Canvas canvas, Paint stroke, Paint fill, int i) {
    switch (i) {
      case 0: // Graduation Cap
        final path = Path()
          ..moveTo(0, -6)
          ..lineTo(14, 0)
          ..lineTo(0, 6)
          ..lineTo(-14, 0)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        canvas.drawLine(const Offset(10, 0), const Offset(12, 10), stroke);
        break;
      case 1: // Teacher Badge / ID
        final rect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-10, -10, 20, 20),
          const Radius.circular(5),
        );
        canvas.drawRRect(rect, fill);
        canvas.drawRRect(rect, stroke);
        canvas.drawCircle(const Offset(0, -3), 3.5, stroke);
        canvas.drawLine(const Offset(-6, 5), const Offset(6, 5), stroke);
        break;
      case 2: // Glasses / Wisdom
        canvas.drawCircle(const Offset(-6, 0), 4.5, stroke);
        canvas.drawCircle(const Offset(6, 0), 4.5, stroke);
        canvas.drawLine(const Offset(-1.5, 0), const Offset(1.5, 0), stroke);
        break;
      case 3: // Open Book
        _drawOpenBook(canvas, stroke, fill);
        break;
      case 4: // Star / Excellence
        _drawStar(canvas, stroke, fill, 8);
        break;
      case 5: // Pen
        _drawPencil(canvas, stroke);
        break;
    }
  }

  // 2. Subjects Motifs
  void _drawSubjectsMotif(Canvas canvas, Paint stroke, Paint fill, int i) {
    switch (i) {
      case 0: // Book with bookmark
        _drawOpenBook(canvas, stroke, fill);
        break;
      case 1: // Math Sigma & Pi
        final path = Path()
          ..moveTo(8, -8)
          ..lineTo(-6, -8)
          ..lineTo(0, 0)
          ..lineTo(-6, 8)
          ..lineTo(8, 8);
        canvas.drawPath(path, stroke);
        break;
      case 2: // Flask / Chemistry
        final path = Path()
          ..moveTo(-3, -10)
          ..lineTo(3, -10)
          ..moveTo(0, -10)
          ..lineTo(0, -3)
          ..lineTo(8, 8)
          ..lineTo(-8, 8)
          ..lineTo(0, -3);
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
      case 3: // Pencil & Ruler
        _drawRuler(canvas, stroke);
        break;
      case 4: // Atom
        _drawAtom(canvas, stroke);
        break;
      case 5: // ABC Book
        final rect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-9, -11, 18, 22),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, fill);
        canvas.drawRRect(rect, stroke);
        canvas.drawLine(const Offset(-5, -4), const Offset(5, -4), stroke);
        canvas.drawLine(const Offset(-5, 1), const Offset(5, 1), stroke);
        break;
    }
  }

  // 3. Setup Mode / Speed Motifs
  void _drawSetupMotif(Canvas canvas, Paint stroke, Paint fill, int i) {
    switch (i) {
      case 0: // Rocket
        final path = Path()
          ..moveTo(0, -12)
          ..quadraticBezierTo(7, -4, 5, 8)
          ..lineTo(-5, 8)
          ..quadraticBezierTo(-7, -4, 0, -12)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        canvas.drawCircle(const Offset(0, -1), 2.5, stroke);
        break;
      case 1: // Gear / Settings
        canvas.drawCircle(Offset.zero, 6, stroke);
        for (int a = 0; a < 6; a++) {
          final rad = a * (math.pi / 3);
          canvas.drawLine(
            Offset(math.cos(rad) * 6, math.sin(rad) * 6),
            Offset(math.cos(rad) * 9, math.sin(rad) * 9),
            stroke,
          );
        }
        break;
      case 2: // Lightning Bolt
        final path = Path()
          ..moveTo(2, -10)
          ..lineTo(-5, 1)
          ..lineTo(0, 1)
          ..lineTo(-2, 10)
          ..lineTo(6, -1)
          ..lineTo(1, -1)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
      case 3: // Sliders / Tune
        canvas.drawLine(const Offset(-8, -5), const Offset(8, -5), stroke);
        canvas.drawCircle(const Offset(-2, -5), 2.5, stroke);
        canvas.drawLine(const Offset(-8, 5), const Offset(8, 5), stroke);
        canvas.drawCircle(const Offset(3, 5), 2.5, stroke);
        break;
      case 4: // Check Badge
        canvas.drawCircle(Offset.zero, 7, fill);
        canvas.drawCircle(Offset.zero, 7, stroke);
        canvas.drawLine(const Offset(-3, 0), const Offset(-1, 3), stroke);
        canvas.drawLine(const Offset(-1, 3), const Offset(4, -3), stroke);
        break;
      case 5: // Fast Sparkle
        _drawStar(canvas, stroke, fill, 7);
        break;
    }
  }

  // 4. Theme & Font Motifs
  void _drawThemeMotif(Canvas canvas, Paint stroke, Paint fill, int i) {
    switch (i) {
      case 0: // Crescent Moon
        final path = Path()
          ..moveTo(0, -9)
          ..cubicTo(6, -9, 9, -4, 9, 2)
          ..cubicTo(9, 7, 5, 9, 0, 9)
          ..cubicTo(4, 6, 4, -4, 0, -9)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
      case 1: // Sun
        canvas.drawCircle(Offset.zero, 4.5, stroke);
        for (int a = 0; a < 8; a++) {
          final rad = a * (math.pi / 4);
          canvas.drawLine(
            Offset(math.cos(rad) * 6, math.sin(rad) * 6),
            Offset(math.cos(rad) * 9, math.sin(rad) * 9),
            stroke,
          );
        }
        break;
      case 2: // Color Palette
        canvas.drawCircle(Offset.zero, 8, fill);
        canvas.drawCircle(Offset.zero, 8, stroke);
        canvas.drawCircle(const Offset(-3, -3), 1.5, stroke);
        canvas.drawCircle(const Offset(3, -3), 1.5, stroke);
        canvas.drawCircle(const Offset(3, 3), 1.5, stroke);
        break;
      case 3: // Letter 'A' (Typography)
        final path = Path()
          ..moveTo(-6, 8)
          ..lineTo(0, -8)
          ..lineTo(6, 8);
        canvas.drawPath(path, stroke);
        canvas.drawLine(const Offset(-4, 2), const Offset(4, 2), stroke);
        break;
      case 4: // Paint Brush
        final path = Path()
          ..moveTo(6, -8)
          ..lineTo(8, -6)
          ..lineTo(0, 4)
          ..lineTo(-4, 4)
          ..lineTo(-4, 0)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
      case 5: // Contrast Circle (Half filled)
        canvas.drawCircle(Offset.zero, 7, stroke);
        final halfPath = Path()
          ..addArc(Rect.fromCircle(center: Offset.zero, radius: 7), -math.pi / 2, math.pi)
          ..close();
        canvas.drawPath(halfPath, fill);
        break;
    }
  }

  // 5. Security Motifs
  void _drawSecurityMotif(Canvas canvas, Paint stroke, Paint fill, int i) {
    switch (i) {
      case 0: // Shield
        final path = Path()
          ..moveTo(0, -10)
          ..lineTo(8, -6)
          ..lineTo(8, 2)
          ..quadraticBezierTo(8, 8, 0, 11)
          ..quadraticBezierTo(-8, 8, -8, 2)
          ..lineTo(-8, -6)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
      case 1: // Padlock
        final body = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-7, -2, 14, 11),
          const Radius.circular(3),
        );
        canvas.drawRRect(body, fill);
        canvas.drawRRect(body, stroke);
        final arch = Path()
          ..moveTo(-4, -2)
          ..lineTo(-4, -6)
          ..arcToPoint(const Offset(4, -6), radius: const Radius.circular(4))
          ..lineTo(4, -2);
        canvas.drawPath(arch, stroke);
        canvas.drawCircle(const Offset(0, 3), 1.5, stroke);
        break;
      case 2: // Key
        canvas.drawCircle(const Offset(-4, 0), 4, stroke);
        canvas.drawLine(const Offset(0, 0), const Offset(9, 0), stroke);
        canvas.drawLine(const Offset(6, 0), const Offset(6, 3), stroke);
        canvas.drawLine(const Offset(9, 0), const Offset(9, 3), stroke);
        break;
      case 3: // Biometric / Fingerprint loop
        canvas.drawArc(
          const Rect.fromLTWH(-4, -6, 8, 12),
          -math.pi / 2,
          math.pi,
          false,
          stroke,
        );
        canvas.drawArc(
          const Rect.fromLTWH(-7, -9, 14, 18),
          -math.pi / 2,
          math.pi,
          false,
          stroke,
        );
        break;
      case 4: // PIN dots
        canvas.drawCircle(const Offset(-6, 0), 2, fill);
        canvas.drawCircle(const Offset(-6, 0), 2, stroke);
        canvas.drawCircle(const Offset(0, 0), 2, fill);
        canvas.drawCircle(const Offset(0, 0), 2, stroke);
        canvas.drawCircle(const Offset(6, 0), 2, fill);
        canvas.drawCircle(const Offset(6, 0), 2, stroke);
        break;
      case 5: // Shield with check
        final path = Path()
          ..moveTo(0, -9)
          ..lineTo(7, -5)
          ..lineTo(7, 2)
          ..quadraticBezierTo(7, 7, 0, 10)
          ..quadraticBezierTo(-7, 7, -7, 2)
          ..lineTo(-7, -5)
          ..close();
        canvas.drawPath(path, stroke);
        canvas.drawLine(const Offset(-3, 1), const Offset(-1, 3.5), stroke);
        canvas.drawLine(const Offset(-1, 3.5), const Offset(3.5, -2), stroke);
        break;
    }
  }

  // 6. Permissions Motifs
  void _drawPermissionsMotif(Canvas canvas, Paint stroke, Paint fill, int i) {
    switch (i) {
      case 0: // Bell
        final path = Path()
          ..moveTo(-6, 4)
          ..lineTo(6, 4)
          ..lineTo(5, 0)
          ..quadraticBezierTo(4, -6, 0, -7)
          ..quadraticBezierTo(-4, -6, -5, 0)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        canvas.drawCircle(const Offset(0, 6.5), 1.5, stroke);
        break;
      case 1: // Alarm Clock
        canvas.drawCircle(Offset.zero, 6.5, fill);
        canvas.drawCircle(Offset.zero, 6.5, stroke);
        canvas.drawLine(Offset.zero, const Offset(0, -4), stroke);
        canvas.drawLine(Offset.zero, const Offset(2.5, 0), stroke);
        // ears
        canvas.drawLine(const Offset(-5, -6), const Offset(-7, -8), stroke);
        canvas.drawLine(const Offset(5, -6), const Offset(7, -8), stroke);
        break;
      case 2: // Contacts Icon
        final body = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-8, -9, 16, 18),
          const Radius.circular(3),
        );
        canvas.drawRRect(body, fill);
        canvas.drawRRect(body, stroke);
        canvas.drawCircle(const Offset(0, -3), 2.5, stroke);
        canvas.drawLine(const Offset(-4, 4), const Offset(4, 4), stroke);
        break;
      case 3: // Signal / Sound waves
        canvas.drawArc(
          const Rect.fromLTWH(-4, -4, 8, 8),
          -math.pi / 3,
          2 * math.pi / 3,
          false,
          stroke,
        );
        canvas.drawArc(
          const Rect.fromLTWH(-8, -8, 16, 16),
          -math.pi / 3,
          2 * math.pi / 3,
          false,
          stroke,
        );
        break;
      case 4: // Checkmark Circle
        canvas.drawCircle(Offset.zero, 6.5, fill);
        canvas.drawCircle(Offset.zero, 6.5, stroke);
        canvas.drawLine(const Offset(-3, 0), const Offset(-1, 2.5), stroke);
        canvas.drawLine(const Offset(-1, 2.5), const Offset(3.5, -2), stroke);
        break;
      case 5: // Clock
        canvas.drawCircle(Offset.zero, 7, stroke);
        canvas.drawLine(Offset.zero, const Offset(0, -4), stroke);
        canvas.drawLine(Offset.zero, const Offset(3, 1), stroke);
        break;
    }
  }

  // 7. Community & Egypt Teachers Motifs
  void _drawCommunityMotif(Canvas canvas, Paint stroke, Paint fill, int i) {
    switch (i) {
      case 0: // Chat Bubble
        final path = Path()
          ..moveTo(-8, -6)
          ..lineTo(8, -6)
          ..quadraticBezierTo(9, -6, 9, -5)
          ..lineTo(9, 3)
          ..quadraticBezierTo(9, 4, 8, 4)
          ..lineTo(-2, 4)
          ..lineTo(-6, 8)
          ..lineTo(-5, 4)
          ..lineTo(-8, 4)
          ..quadraticBezierTo(-9, 4, -9, 3)
          ..lineTo(-9, -5)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
      case 1: // Egypt Pyramid Silhouette
        final path = Path()
          ..moveTo(0, -9)
          ..lineTo(11, 7)
          ..lineTo(-11, 7)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        canvas.drawLine(const Offset(0, -9), const Offset(2, 7), stroke);
        break;
      case 2: // Teachers / People Network
        canvas.drawCircle(const Offset(-5, -3), 3, stroke);
        canvas.drawCircle(const Offset(5, -3), 3, stroke);
        canvas.drawArc(const Rect.fromLTWH(-9, 1, 8, 8), math.pi, math.pi, false, stroke);
        canvas.drawArc(const Rect.fromLTWH(1, 1, 8, 8), math.pi, math.pi, false, stroke);
        break;
      case 3: // WhatsApp / Phone receiver in bubble
        canvas.drawCircle(Offset.zero, 7.5, fill);
        canvas.drawCircle(Offset.zero, 7.5, stroke);
        final phone = Path()
          ..moveTo(-3, -3)
          ..quadraticBezierTo(0, -4, 3, -2)
          ..lineTo(2, 0)
          ..lineTo(0, 2)
          ..lineTo(-2, 0)
          ..close();
        canvas.drawPath(phone, stroke);
        break;
      case 4: // Heart / Support
        final path = Path()
          ..moveTo(0, 3)
          ..cubicTo(-6, -3, -6, -7, 0, -5)
          ..cubicTo(6, -7, 6, -3, 0, 3)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
      case 5: // Celebration Star
        _drawStar(canvas, stroke, fill, 7.5);
        break;
    }
  }

  // 8. Features Showcase Motifs
  void _drawFeaturesMotif(Canvas canvas, Paint stroke, Paint fill, int i) {
    switch (i) {
      case 0: // Trophy
        final path = Path()
          ..moveTo(-6, -8)
          ..lineTo(6, -8)
          ..lineTo(4, 0)
          ..quadraticBezierTo(0, 4, 0, 5)
          ..lineTo(-2, 8)
          ..lineTo(2, 8)
          ..moveTo(0, 5)
          ..quadraticBezierTo(0, 4, -4, 0)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
      case 1: // Bar Chart
        canvas.drawLine(const Offset(-8, 8), const Offset(8, 8), stroke);
        canvas.drawRect(const Rect.fromLTWH(-6, 2, 3, 6), fill);
        canvas.drawRect(const Rect.fromLTWH(-6, 2, 3, 6), stroke);
        canvas.drawRect(const Rect.fromLTWH(-1, -3, 3, 11), fill);
        canvas.drawRect(const Rect.fromLTWH(-1, -3, 3, 11), stroke);
        canvas.drawRect(const Rect.fromLTWH(4, -7, 3, 15), fill);
        canvas.drawRect(const Rect.fromLTWH(4, -7, 3, 15), stroke);
        break;
      case 2: // Diamond / VIP
        final path = Path()
          ..moveTo(0, -8)
          ..lineTo(8, -1)
          ..lineTo(0, 8)
          ..lineTo(-8, -1)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
      case 3: // Medal / Ribbon
        canvas.drawCircle(const Offset(0, -2), 5, fill);
        canvas.drawCircle(const Offset(0, -2), 5, stroke);
        canvas.drawLine(const Offset(-3, 2), const Offset(-5, 8), stroke);
        canvas.drawLine(const Offset(3, 2), const Offset(5, 8), stroke);
        break;
      case 4: // Sparkle Star
        _drawStar(canvas, stroke, fill, 8);
        break;
      case 5: // Crown
        final path = Path()
          ..moveTo(-8, 5)
          ..lineTo(-8, -3)
          ..lineTo(-4, 0)
          ..lineTo(0, -5)
          ..lineTo(4, 0)
          ..lineTo(8, -3)
          ..lineTo(8, 5)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
    }
  }

  // Common Utilities
  void _drawOpenBook(Canvas canvas, Paint stroke, Paint fill) {
    final path = Path()
      ..moveTo(0, -2)
      ..cubicTo(4, -6, 9, -5, 11, -4)
      ..lineTo(11, 6)
      ..cubicTo(9, 5, 4, 4, 0, 7)
      ..cubicTo(-4, 4, -9, 5, -11, 6)
      ..lineTo(-11, -4)
      ..cubicTo(-9, -5, -4, -6, 0, -2)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    canvas.drawLine(const Offset(0, -2), const Offset(0, 7), stroke);
  }

  void _drawPencil(Canvas canvas, Paint stroke) {
    final path = Path()
      ..moveTo(6, -8)
      ..lineTo(8, -6)
      ..lineTo(-3, 5)
      ..lineTo(-7, 7)
      ..lineTo(-5, 3)
      ..close();
    canvas.drawPath(path, stroke);
  }

  void _drawRuler(Canvas canvas, Paint stroke) {
    canvas.save();
    canvas.rotate(-math.pi / 4);
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-10, -3, 20, 6),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(rect, stroke);
    canvas.drawLine(const Offset(-6, -3), const Offset(-6, 0), stroke);
    canvas.drawLine(const Offset(-2, -3), const Offset(-2, 0), stroke);
    canvas.drawLine(const Offset(2, -3), const Offset(2, 0), stroke);
    canvas.drawLine(const Offset(6, -3), const Offset(6, 0), stroke);
    canvas.restore();
  }

  void _drawAtom(Canvas canvas, Paint stroke) {
    canvas.drawCircle(Offset.zero, 2.5, stroke);
    canvas.drawOval(
      const Rect.fromLTWH(-9, -4.5, 18, 9),
      stroke,
    );
    canvas.save();
    canvas.rotate(math.pi / 3);
    canvas.drawOval(
      const Rect.fromLTWH(-9, -4.5, 18, 9),
      stroke,
    );
    canvas.restore();
  }

  void _drawStar(Canvas canvas, Paint stroke, Paint fill, double radius) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final double outerAngle = i * (2 * math.pi / 5) - math.pi / 2;
      final double innerAngle = outerAngle + math.pi / 5;
      final double ox = math.cos(outerAngle) * radius;
      final double oy = math.sin(outerAngle) * radius;
      final double ix = math.cos(innerAngle) * (radius * 0.45);
      final double iy = math.sin(innerAngle) * (radius * 0.45);

      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _StepPatternPainter oldDelegate) {
    return oldDelegate.stepType != stepType || oldDelegate.isDark != isDark;
  }
}
