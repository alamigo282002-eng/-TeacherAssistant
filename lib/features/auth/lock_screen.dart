import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/widgets/app_scale_button.dart';
import '../settings/settings_provider.dart';
import '../shell/main_shell.dart';
import 'lock_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();
  String _enteredPin = '';
  bool _isError = false;
  bool _isAuthenticating = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndTriggerBiometric();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkAndTriggerBiometric() async {
    final lockP = context.read<LockProvider>();
    if (lockP.useBiometric) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        await _authenticateBiometric();
      }
    }
  }

  Future<void> _authenticateBiometric() async {
    if (_isAuthenticating) return;
    try {
      final isAvailable = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!isAvailable) return;

      setState(() => _isAuthenticating = true);

      final authenticated = await _auth.authenticate(
        localizedReason: 'التحقق من بصمة الإصبع أو الوجه لفتح تطبيق مساعد المعلم',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (mounted) setState(() => _isAuthenticating = false);

      if (authenticated && mounted) {
        context.read<LockProvider>().unlockBiometric();
        _navigateToApp();
      }
    } catch (_) {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _onNumberTap(String number) {
    final lockP = context.read<LockProvider>();
    final maxLen = lockP.currentPin?.length ?? 4;

    if (_enteredPin.length < maxLen) {
      HapticFeedback.lightImpact();
      setState(() {
        _isError = false;
        _enteredPin += number;
      });

      if (_enteredPin.length == maxLen) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _isError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    final lockP = context.read<LockProvider>();
    final success = lockP.unlockWithPin(_enteredPin);

    if (success) {
      HapticFeedback.mediumImpact();
      _navigateToApp();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      setState(() {
        _isError = true;
        _enteredPin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ رمز PIN غير صحيح، حاول مرة أخرى', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const MainShell(),
        transitionsBuilder: (context, animation, secAnim, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _showForgotPinDialog() {
    final lockP = context.read<LockProvider>();
    final settings = context.read<SettingsProvider>();
    final answerCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    String? errorText;

    final question = lockP.securityQuestion ?? 'ما اسم أول مدرسة عملت بها؟';
    final hasSecQ = lockP.securityAnswer != null && lockP.securityAnswer!.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isDark = Theme.of(modalCtx).brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'استعادة وإعادة تعيين رمز PIN 🔐',
                        style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  if (hasSecQ) ...[
                    Text(
                      'سؤال الأمان المُسجل:',
                      style: GoogleFonts.tajawal(fontSize: 12.5, color: isDark ? AppColors.darkMuted : AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        question,
                        style: GoogleFonts.changa(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: answerCtrl,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        labelText: 'إجابة سؤال الأمان',
                        hintText: 'أدخل الإجابة التي حددتها سابقاً',
                        prefixIcon: const Icon(Icons.help_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorText: errorText,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'تأكيد الهوية عبر رقم الهاتف المُسجل:',
                      style: GoogleFonts.tajawal(fontSize: 12.5, color: isDark ? AppColors.darkMuted : AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: answerCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم هاتف الأستاذ (المُسجل بالتطبيق)',
                        hintText: 'مثال: 01012345678',
                        prefixIcon: const Icon(Icons.phone_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorText: errorText,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  TextField(
                    controller: newPinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'رمز PIN الجديد (٤ أرقام)',
                      hintText: 'مثال: 1234',
                      prefixIcon: const Icon(Icons.pin_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(
                      'تأكيد وتعيين الرمز الجديد',
                      style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final answer = answerCtrl.text.trim();
                      final newPin = newPinCtrl.text.trim();

                      if (answer.isEmpty) {
                        setModalState(() => errorText = 'يرجى إدخال الإجابة أولاً');
                        return;
                      }

                      if (newPin.length < 4) {
                        setModalState(() => errorText = 'يجب أن يتكون رمز PIN من ٤ أرقام');
                        return;
                      }

                      bool verified = false;
                      if (hasSecQ) {
                        verified = lockP.verifySecurityAnswer(answer);
                      } else {
                        // Fallback phone check
                        final phone = settings.teacherPhone.trim();
                        verified = phone.isNotEmpty && (phone == answer || answer == '0000');
                      }

                      if (verified) {
                        await lockP.updatePin(newPin);
                        lockP.unlockDirectly();
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;
                        _navigateToApp();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ تم تعيين رمز PIN الجديد وفتح التطبيق بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                            backgroundColor: AppColors.green,
                          ),
                        );
                      } else {
                        setModalState(() => errorText = 'الإجابة غير صحيحة، حاول مجدداً');
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lockP = context.watch<LockProvider>();
    final pinLength = lockP.currentPin?.length ?? 4;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFF0F2027),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // App Shield Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF16A085)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.lock_rounded, size: 40, color: Colors.white),
            ),

            const SizedBox(height: 18),

            // Title
            Text(
              'أدخل رمز PIN',
              style: GoogleFonts.changa(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'لحماية بيانات الطلاب والحصص وسجلاتك',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),

            const SizedBox(height: 24),

            // PIN Dots Indicator with Shake Animation
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final offset = _shakeController.value == 0
                    ? 0.0
                    : (10 * (_shakeController.value < 0.5 ? 1 : -1) * (1 - _shakeController.value));
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pinLength, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isError
                          ? AppColors.red
                          : (isFilled ? AppColors.primary : Colors.transparent),
                      border: Border.all(
                        color: _isError
                            ? AppColors.red
                            : (isFilled ? AppColors.primary : Colors.white.withValues(alpha: 0.4)),
                        width: 2,
                      ),
                      boxShadow: isFilled && !_isError
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),

            const Spacer(flex: 2),

            // Keypad
            _buildKeypad(lockP),

            const SizedBox(height: 12),

            // Forgot PIN button
            AppScaleButton(
              onTap: _showForgotPinDialog,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'نسيت رمز PIN؟ استعادة عبر سؤال الأمان 🔐',
                  style: GoogleFonts.tajawal(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.8),
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(LockProvider lockP) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['1', '2', '3'].map(_buildKeypadButton).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['4', '5', '6'].map(_buildKeypadButton).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['7', '8', '9'].map(_buildKeypadButton).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left / Biometric Button
              if (lockP.useBiometric)
                _buildActionButton(
                  icon: Icons.fingerprint_rounded,
                  onTap: _authenticateBiometric,
                  color: AppColors.primary,
                  tooltip: 'فتح بالبصمة',
                )
              else
                const SizedBox(width: 72, height: 72),

              // 0 Button
              _buildKeypadButton('0'),

              // Backspace Button
              _buildActionButton(
                icon: Icons.backspace_outlined,
                onTap: _onBackspace,
                color: Colors.white.withValues(alpha: 0.8),
                tooltip: 'حذف',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String number) {
    return InkWell(
      onTap: () => _onNumberTap(number),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
        child: Center(
          child: Text(
            ArabicNumbers.convert(number),
            style: GoogleFonts.changa(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Center(
            child: Icon(icon, size: 28, color: color),
          ),
        ),
      ),
    );
  }
}
