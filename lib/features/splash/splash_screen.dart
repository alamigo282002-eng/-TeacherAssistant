import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/dot_grid_pattern.dart';
import '../auth/lock_provider.dart';
import '../auth/lock_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../settings/settings_provider.dart';
import '../shell/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // 1. Ensure lock provider settings are fully loaded
    final lockP = context.read<LockProvider>();
    await lockP.loadSettings();

    // 2. Display splash duration
    await Future.delayed(const Duration(milliseconds: 1700));

    if (!mounted) return;

    final settings = context.read<SettingsProvider>();

    // 3. Navigate to appropriate destination
    Widget nextScreen;
    if (lockP.isLocked) {
      nextScreen = const LockScreen();
    } else if (settings.onboardingDone) {
      nextScreen = const MainShell();
    } else {
      nextScreen = const OnboardingScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = settings.splashTheme;

    switch (theme) {
      case 'modern':
        return _buildModernSplash();
      case 'gold':
        return _buildGoldSplash();
      case 'minimal':
        return _buildMinimalSplash();
      case 'emerald':
      default:
        return _buildEmeraldSplash();
    }
  }

  // 🌿 1. Emerald Classic Style
  Widget _buildEmeraldSplash() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2E1E),
      body: DotGridSurface(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2215), Color(0xFF134E2E), Color(0xFF1B6B40)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 72,
                  color: AppColors.primary,
                ),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 600.ms),

              const SizedBox(height: 22),

              Text(
                'مساعد المعلم',
                style: GoogleFonts.changa(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              )
                  .animate(delay: 200.ms)
                  .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 6),

              Text(
                'المنظومة الاحترافية لإدارة الحصص والطلاب',
                style: GoogleFonts.tajawal(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              )
                  .animate(delay: 350.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 38),

              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Color(0xFF6EE7B7),
                  strokeWidth: 2.5,
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 350.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ 2. Modern Cyber Glow Style
  Widget _buildModernSplash() {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 0.9,
            colors: [Color(0xFF1E293B), Color(0xFF090D16)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_stories_rounded, size: 54, color: Colors.white),
              )
                  .animate()
                  .scale(duration: 550.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 24),

              Text(
                'مساعد المعلم 🚀',
                style: GoogleFonts.changa(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 6),

              Text(
                'رفيقك الذكي نحو إدارة تعليمية متميزة',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
              ).animate(delay: 350.ms).fadeIn(),

              const SizedBox(height: 36),

              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Color(0xFF10B981),
                  strokeWidth: 2.5,
                ),
              ).animate(delay: 500.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  // 🏛️ 3. Royal Gold Style
  Widget _buildGoldSplash() {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF292524)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFB45309)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 26,
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 68, color: Colors.white),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 600.ms),

              const SizedBox(height: 22),

              Text(
                'مساعد المعلم',
                style: GoogleFonts.changa(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFDE68A),
                ),
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 6),

              Text(
                'قمة الاحترافية والدقة في إدارة الحصص',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: const Color(0xFFE2E8F0),
                ),
              ).animate(delay: 350.ms).fadeIn(),

              const SizedBox(height: 38),

              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Color(0xFFF59E0B),
                  strokeWidth: 2.5,
                ),
              ).animate(delay: 500.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  // 💡 4. Minimalist Pure Style
  Widget _buildMinimalSplash() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 76, color: Color(0xFF38BDF8))
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1)),

            const SizedBox(height: 20),

            Text(
              'مساعد المعلم',
              style: GoogleFonts.changa(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 6),

            Text(
              'تعليم اليوم .. قادة الغد 🌱',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
            ).animate(delay: 350.ms).fadeIn(),

            const SizedBox(height: 36),

            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF38BDF8),
                strokeWidth: 2.2,
              ),
            ).animate(delay: 450.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
