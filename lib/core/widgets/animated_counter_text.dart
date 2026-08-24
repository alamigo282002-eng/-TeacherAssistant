import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/arabic_numbers.dart';

/// ويدجت عداد رقمي متحرك يقوم بعد الأرقام تصاعدياً بسلاسة 60fps
/// ملاحظة: يُفضل استخدام خط Tajawal للأرقام العربية بدلاً من Changa لأن ٠ بتظهر كنقطة في Changa
class AnimatedCounterText extends StatelessWidget {
  final int count;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String? prefix;
  final String? suffix;

  const AnimatedCounterText({
    super.key,
    required this.count,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    // When count is 0, skip animation and show ٠ directly to avoid rendering issues
    if (count == 0) {
      final zeroText = '${prefix ?? ''}٠${suffix ?? ''}';
      return Text(
        zeroText,
        style: _ensureClearFont(style),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: count.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        final currentInt = value.round();
        final text = ArabicNumbers.convert(currentInt);
        final fullText = '${prefix ?? ''}$text${suffix ?? ''}';

        return Text(
          fullText,
          style: _ensureClearFont(style),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  /// Ensures numbers use a clear font that renders Arabic-Indic digits properly
  TextStyle? _ensureClearFont(TextStyle? original) {
    if (original == null) return GoogleFonts.tajawal(fontWeight: FontWeight.bold);
    // Override fontFamily to Tajawal for clear Arabic digit rendering
    return GoogleFonts.tajawal(
      fontSize: original.fontSize,
      fontWeight: original.fontWeight,
      color: original.color,
      letterSpacing: original.letterSpacing,
      height: original.height,
    );
  }
}
