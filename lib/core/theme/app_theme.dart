import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Palette (مستوحاة بدقة من باليت Noguchi Green: #022B22, #275D46, #569578, #101C13)
  static const Color pineGreen = Color(0xFF022B22); // #022b22
  static const Color forestGreen = Color(0xFF275D46); // #275d46
  static const Color sageGreen = Color(0xFF569578); // #569578
  static const Color obsidianForest = Color(0xFF101C13); // #101c13

  // Light Palette (🌞 لايت زمردي وغابي فخم)
  static const Color primary = Color(0xFF275D46); // الأخضر الغابي الأساسي (#275d46)
  static const Color primaryDark = Color(0xFF022B22); // الأخضر الصنوبري (#022b22)
  static const Color primaryLight = Color(0xFF569578); // أخضر الميرمية (#569578)
  static const Color lime = Color(0xFF569578);
  
  static const Color orange = Color(0xFFD97706);
  static const Color orangeSoft = Color(0xFFFEF3C7);
  static const Color red = Color(0xFFD64545);
  static const Color redSoft = Color(0xFFFEE2E2);
  
  static const Color bg = Color(0xFFF3F7F5); // خلفية نقية بلمسة خضراء هادئة
  static const Color card = Color(0xFFFFFFFF); // كروت بيضاء نقية
  static const Color ink = Color(0xFF101C13); // النص الأساسي شديد الوضوح (#101c13)
  static const Color muted = Color(0xFF536E60); // النص الثانوي
  static const Color border = Color(0xFFDBE7E1); // الحدود
  static const Color currentTimeline = Color(0xFF275D46); // خط الوقت الحالي لايت

  // Chip & Badge Soft Colors
  static const Color chipTeal = Color(0xFFE7F3ED);
  static const Color chipTealText = Color(0xFF275D46);
  static const Color green = Color(0xFF275D46);
  static const Color greenSoft = Color(0xFFE2F0E8);

  // Dark Palette (🌙 دارك أوبسيديان زمردي فخم)
  static const Color darkBg = Color(0xFF101C13); // أسود أوبسيديان مخضر (#101c13)
  static const Color obsidianBg = Color(0xFF101C13);
  static const Color darkCard = Color(0xFF16251B); // كروت داكنة بلمسة صنوبرية
  static const Color darkCardAlt = Color(0xFF1C3023); // كروت شبكة المزيد والتقويم
  static const Color darkSurface = Color(0xFF223A2B); // الأسطح والحقول
  static const Color darkPrimary = Color(0xFF6EAF90); // الأخضر الفاتح المضيء (#569578 مضيء)
  static const Color periwinklePill = Color(0xFFA5C9B8);
  static const Color periwinklePillText = Color(0xFF101C13);
  static const Color buttonSquareBlue = Color(0xFF275D46);
  static const Color darkPrimaryDark = Color(0xFF275D46);
  static const Color darkPrimaryLight = Color(0xFF87C2A6);
  static const Color darkLime = Color(0xFF87C2A6);
  static const Color darkOrange = Color(0xFFFBBF24);
  static const Color darkOrangeSoft = Color(0x2BFBBF24);
  static const Color darkRed = Color(0xFFF87171);
  static const Color darkRedSoft = Color(0x2BF87171);
  static const Color darkText = Color(0xFFF2F8F5);
  static const Color darkMuted = Color(0xFFB4CCC0); // نصوص ثانوية فائقة الوضوح والتباين في الدارك مود
  static const Color darkBorder = Color(0xFF284435);
  static const Color darkGreenSoft = Color(0x28569578);
  static const Color darkCurrentTimeline = Color(0xFF6EAF90); // خط الوقت الحالي دارك

  // Consistent Group Colors Palette
  static const List<Color> groupPalette = [
    Color(0xFF275D46), // 🟢 أخضر غابي (#275d46)
    Color(0xFF569578), // 🌿 أخضر ميرمية (#569578)
    Color(0xFFD97706), // 🟠 عنبري دافئ
    Color(0xFF0E8A75), // 🩵 تركواز عميق
    Color(0xFF2563EB), // 🔵 أزرق ملكي
    Color(0xFF8B5CF6), // 🟣 بنفسجي
    Color(0xFFE11D48), // 🌸 وردي ياقوتي
    Color(0xFF022B22), // 🌲 صنوبري داكن (#022b22)
  ];

  // Gradients (مستوحاة من تناغمات الألوان بالصورة: #022b22, #275d46, #569578)
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF022B22), Color(0xFF275D46)],
  );

  static const LinearGradient darkHeaderGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF0B140E), Color(0xFF022B22)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF022B22), Color(0xFF275D46), Color(0xFF569578)],
  );

  static const LinearGradient limeGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF275D46), Color(0xFF569578)],
  );

  static const LinearGradient darkAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF275D46), Color(0xFF6EAF90)],
  );

  // Status & Backward-compatibility Aliases
  static const Color success = green;
  static const Color warning = orange;
  static const Color error = red;
  static const Color info = Color(0xFF0284C7);

  static const Color present = green;
  static const Color absent = red;

  static const Color paid = green;
  static const Color partial = orange;
  static const Color unpaid = red;

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color lightText = ink;
  static const Color lightTextSecondary = muted;
  static const Color darkTextSecondary = darkMuted;
  static const Color lightBackground = bg;
  static const Color darkBackground = darkBg;
  static const Color lightBorder = border;
  static const Color accent = orange;

  // ═══════════════════════════════════════════════════════════════
  // 🧪 EXAM MODE — وضع الاختبار: نمط أسود عميق فضائي مع لمسات نيون
  // ═══════════════════════════════════════════════════════════════
  static const Color examBg = Color(0xFF050C0E);
  static const Color examCard = Color(0xFF0D1519);
  static const Color examCardAlt = Color(0xFF11201F);
  static const Color examSurface = Color(0xFF152120);
  static const Color examBorder = Color(0xFF1E3530);
  static const Color examBorderAccent = Color(0xFF00FFCC);

  // النيون الزمردي الكهربائي — اللون الأساسي
  static const Color examPrimary = Color(0xFF00E5CC);
  static const Color examPrimaryGlow = Color(0xFF00FFCC);
  static const Color examPrimaryDim = Color(0xFF004D44);

  // الذهبي الكهرماني — الأكسنت الثانوي
  static const Color examGold = Color(0xFFFFC84A);
  static const Color examGoldDim = Color(0xFF2E1F00);

  // نص ومكوّنات
  static const Color examText = Color(0xFFE8F6F4);
  static const Color examMuted = Color(0xFF6B9E9A);
  static const Color examRed = Color(0xFFFF5C6A);
  static const Color examRedDim = Color(0x33FF5C6A);
  static const Color examGreen = Color(0xFF00E5B0);
  static const Color examOrange = Color(0xFFFFAA00);
  static const Color examOrangeDim = Color(0x33FFAA00);

  // Gradients
  static const LinearGradient examHeaderGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF030A0C), Color(0xFF0D2320), Color(0xFF001A17)],
  );
  static const LinearGradient examAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5CC), Color(0xFF009E8D)],
  );
  static const LinearGradient examGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC84A), Color(0xFFFF8F00)],
  );
  static const LinearGradient examNextGroupGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF001F1C), Color(0xFF00373A), Color(0xFF004D44)],
  );
}

class AppTheme {
  static ThemeData lightTheme({bool isBold = false}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.card,
        error: AppColors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.ink,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(AppColors.ink, AppColors.muted, isBold: isBold),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.changa(
          fontSize: 18,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SmoothSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: SmoothSlidePageTransitionsBuilder(),
          TargetPlatform.windows: SmoothSlidePageTransitionsBuilder(),
          TargetPlatform.linux: SmoothSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: SmoothSlidePageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: _buildInputDecoration(isDark: false),
      elevatedButtonTheme: _buildElevatedButton(isDark: false),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        extendedTextStyle: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipTeal,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.tajawal(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          color: AppColors.chipTealText,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.8,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        selectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData darkTheme({bool isBold = false}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkPrimaryLight,
        surface: AppColors.darkCard,
        error: AppColors.darkRed,
        onPrimary: AppColors.darkBg,
        onSecondary: AppColors.darkBg,
        onSurface: AppColors.darkText,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(AppColors.darkText, AppColors.darkMuted, isBold: isBold),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.changa(
          fontSize: 18,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          color: AppColors.darkText,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.8),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SmoothSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: SmoothSlidePageTransitionsBuilder(),
          TargetPlatform.windows: SmoothSlidePageTransitionsBuilder(),
          TargetPlatform.linux: SmoothSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: SmoothSlidePageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: _buildInputDecoration(isDark: true),
      elevatedButtonTheme: _buildElevatedButton(isDark: true),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkBg,
        elevation: 4,
        extendedTextStyle: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkGreenSoft,
        selectedColor: AppColors.darkPrimary.withValues(alpha: 0.25),
        labelStyle: GoogleFonts.tajawal(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          color: AppColors.darkPrimary,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 0.8,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkMuted,
        selectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }

  /// 🧪 وضع الاختبار — Premium Deep-Space Exam Theme
  static ThemeData examTheme({bool isBold = false}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.examPrimary,
      scaffoldBackgroundColor: AppColors.examBg,
      colorScheme: ColorScheme.dark(
        primary: AppColors.examPrimary,
        secondary: AppColors.examGold,
        surface: AppColors.examCard,
        error: AppColors.examRed,
        onPrimary: AppColors.examBg,
        onSecondary: AppColors.examBg,
        onSurface: AppColors.examText,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(AppColors.examText, AppColors.examMuted, isBold: isBold),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.examBg,
        foregroundColor: AppColors.examText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.changa(
          fontSize: 18,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          color: AppColors.examText,
        ),
        iconTheme: const IconThemeData(color: AppColors.examText),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.examCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.examBorder, width: 0.9),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SmoothSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: SmoothSlidePageTransitionsBuilder(),
          TargetPlatform.windows: SmoothSlidePageTransitionsBuilder(),
          TargetPlatform.linux: SmoothSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: SmoothSlidePageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: _buildInputDecoration(isDark: true, isExam: true),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.examPrimary,
          foregroundColor: AppColors.examBg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.changa(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.examPrimary,
        foregroundColor: AppColors.examBg,
        elevation: 6,
        extendedTextStyle: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.examPrimaryDim,
        selectedColor: AppColors.examPrimary.withValues(alpha: 0.3),
        labelStyle: GoogleFonts.tajawal(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          color: AppColors.examPrimary,
        ),
        side: const BorderSide(color: AppColors.examBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.examBorder,
        thickness: 0.9,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.examCard,
        selectedItemColor: AppColors.examPrimary,
        unselectedItemColor: AppColors.examMuted,
        selectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor, {bool isBold = false}) {
    return TextTheme(
      displayLarge: GoogleFonts.changa(fontSize: 32, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, color: primaryColor),
      displayMedium: GoogleFonts.changa(fontSize: 28, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, color: primaryColor),
      displaySmall: GoogleFonts.changa(fontSize: 24, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, color: primaryColor),
      headlineLarge: GoogleFonts.changa(fontSize: 22, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, color: primaryColor),
      headlineMedium: GoogleFonts.changa(fontSize: 20, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: primaryColor),
      headlineSmall: GoogleFonts.changa(fontSize: 18, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: primaryColor),
      titleLarge: GoogleFonts.changa(fontSize: 16, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, color: primaryColor),
      titleMedium: GoogleFonts.changa(fontSize: 15, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: primaryColor),
      titleSmall: GoogleFonts.changa(fontSize: 14, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: primaryColor),
      bodyLarge: GoogleFonts.tajawal(fontSize: 16, fontWeight: isBold ? FontWeight.w800 : FontWeight.normal, color: primaryColor),
      bodyMedium: GoogleFonts.tajawal(fontSize: 14, fontWeight: isBold ? FontWeight.w800 : FontWeight.normal, color: primaryColor),
      bodySmall: GoogleFonts.tajawal(fontSize: 12, fontWeight: isBold ? FontWeight.w700 : FontWeight.normal, color: secondaryColor),
      labelLarge: GoogleFonts.tajawal(fontSize: 14, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, color: primaryColor),
      labelMedium: GoogleFonts.tajawal(fontSize: 12, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: primaryColor),
      labelSmall: GoogleFonts.tajawal(fontSize: 10, fontWeight: isBold ? FontWeight.w800 : FontWeight.normal, color: secondaryColor),
    );
  }

  static InputDecorationTheme _buildInputDecoration({required bool isDark, bool isExam = false}) {
    final fillColor = isExam ? AppColors.examSurface : (isDark ? const Color(0xFF1E2836) : const Color(0xFFF7FBF8));
    final borderColor = isExam ? AppColors.examBorder : (isDark ? const Color(0xFF334155) : AppColors.border);
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isExam ? AppColors.examPrimary : (isDark ? AppColors.darkPrimary : AppColors.primary),
          width: isExam ? 2.0 : 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isExam ? AppColors.examRed : (isDark ? AppColors.darkRed : AppColors.red), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isExam ? AppColors.examRed : (isDark ? AppColors.darkRed : AppColors.red), width: 1.8),
      ),
      hintStyle: GoogleFonts.tajawal(
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF9AA7A5),
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.tajawal(
        color: isDark ? const Color(0xFFCBD5E1) : AppColors.muted,
        fontSize: 14,
      ),
      errorStyle: GoogleFonts.tajawal(
        color: isDark ? AppColors.darkRed : AppColors.red,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButton({required bool isDark}) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
        foregroundColor: isDark ? AppColors.darkBg : AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.changa(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Custom silky-smooth slide & fade transition builder for modern flutter navigation
class SmoothSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final secondaryCurvedAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.06, 0.0),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.03, 0.0),
          ).animate(secondaryCurvedAnimation),
          child: child,
        ),
      ),
    );
  }
}
