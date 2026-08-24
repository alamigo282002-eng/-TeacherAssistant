import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/educational_pattern_background.dart';
import '../settings/settings_provider.dart';
import 'onboarding_screen.dart';
import 'widgets/specialties_bottom_sheet.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<String> _selectedSpecialties = [];
  bool _loading = false;
  bool _specialtiesError = false;
  bool _biometricEnabled = false;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openSpecialtiesPicker() async {
    final result = await SpecialtiesBottomSheet.show(
      context,
      initialSelected: _selectedSpecialties,
    );

    if (result != null) {
      setState(() {
        _selectedSpecialties = result;
        if (_selectedSpecialties.isNotEmpty) {
          _specialtiesError = false;
        }
      });
    }
  }

  void _removeSpecialty(String item) {
    setState(() {
      _selectedSpecialties.remove(item);
    });
  }

  Future<void> _onSubmit() async {
    setState(() {
      _autoValidateMode = AutovalidateMode.onUserInteraction;
    });

    final bool isValid = _formKey.currentState?.validate() ?? false;

    if (_selectedSpecialties.isEmpty) {
      setState(() => _specialtiesError = true);
    }

    if (!isValid) {
      return;
    }

    setState(() => _loading = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      final settings = context.read<SettingsProvider>();
      await settings.setTeacherName(name.isNotEmpty ? name : 'المعلم');
      await settings.setTeacherPhone(phone);
      await settings.setTeacherSpecialties(_selectedSpecialties);
      await settings.setBiometricEnabled(_biometricEnabled);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, anim1, anim2) => const OnboardingScreen(),
          transitionsBuilder: (ctx, anim, anim2, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e', style: GoogleFonts.cairo()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: EducationalPatternBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),

                        // Floating / Animated Badge
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 48,
                            color: Color(0xFF0D5C5C),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveY(begin: 0, end: -6, duration: 1800.ms, curve: Curves.easeInOut),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          'تسجيل بيانات المعلم',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 4),

                        // Subtitle
                        Text(
                          'أدخل بياناتك الأساسية لبدء تجربة مخصصة',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                        const SizedBox(height: 24),

                        // White Card Form
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            autovalidateMode: _autoValidateMode,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Full Name Field
                                _buildFieldLabel('الاسم بالكامل *'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameController,
                                  textDirection: TextDirection.rtl,
                                  onChanged: (_) {
                                    if (_autoValidateMode == AutovalidateMode.onUserInteraction) {
                                      _formKey.currentState?.validate();
                                    }
                                  },
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    color: const Color(0xFF333333),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'اسمك',
                                    hintStyle: GoogleFonts.cairo(
                                      color: const Color(0xFF999999),
                                      fontSize: 14,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      color: Color(0xFF0D6B6B),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF7F9FA),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF0D8A7A),
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                                  validator: (v) => AppValidators.required(v, 'الاسم بالكامل'),
                                ),

                                const SizedBox(height: 18),

                                // Phone Number Field
                                _buildFieldLabel('رقم الهاتف *'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(15),
                                  ],
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.right,
                                  onChanged: (_) {
                                    if (_autoValidateMode == AutovalidateMode.onUserInteraction) {
                                      _formKey.currentState?.validate();
                                    }
                                  },
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    color: const Color(0xFF333333),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '01xxxxxxxxx',
                                    hintStyle: GoogleFonts.cairo(
                                      color: const Color(0xFF999999),
                                      fontSize: 14,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.phone_android_rounded,
                                      color: Color(0xFF0D6B6B),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF7F9FA),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF0D8A7A),
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    final req = AppValidators.required(v, 'رقم الهاتف');
                                    if (req != null) return req;
                                    return AppValidators.phone(v);
                                  },
                                ),

                                const SizedBox(height: 18),

                                // Academic Specialties Field
                                _buildFieldLabel('التخصصات الأكاديمية'),
                                const SizedBox(height: 6),

                                InkWell(
                                  onTap: _openSpecialtiesPicker,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F9FA),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _specialtiesError
                                            ? AppColors.error
                                            : const Color(0xFFE2E8F0),
                                        width: _specialtiesError ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.school_outlined,
                                          color: Color(0xFF0D6B6B),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _selectedSpecialties.isEmpty
                                                ? 'اختر تخصصك الأكاديمي'
                                                : 'تم اختيار ${_selectedSpecialties.length} تخصص (اضغط للتعديل)',
                                            style: GoogleFonts.cairo(
                                              fontSize: 14,
                                              color: _selectedSpecialties.isEmpty
                                                  ? const Color(0xFF999999)
                                                  : const Color(0xFF0D8A7A),
                                              fontWeight: _selectedSpecialties.isEmpty
                                                  ? FontWeight.normal
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Color(0xFF0D6B6B),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Selected Specialties Tags
                                if (_selectedSpecialties.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _selectedSpecialties.map((specialty) {
                                      return Container(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                          left: 6,
                                          top: 4,
                                          bottom: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F7F4),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFF0D8A7A).withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              specialty,
                                              style: GoogleFonts.cairo(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF0D8A7A),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            InkWell(
                                              onTap: () => _removeSpecialty(specialty),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0D8A7A).withValues(alpha: 0.15),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close_rounded,
                                                  size: 14,
                                                  color: Color(0xFF0D8A7A),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 24),

                        // Biometric Lock Option
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: SwitchListTile(
                            value: _biometricEnabled,
                            onChanged: (val) {
                              setState(() => _biometricEnabled = val);
                            },
                            title: Text(
                              'تفعيل قفل البصمة',
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF333333),
                              ),
                            ),
                            subtitle: Text(
                              'لزيادة الأمان وخصوصية البيانات',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: const Color(0xFF777777),
                              ),
                            ),
                            secondary: const CircleAvatar(
                              backgroundColor: Color(0xFFF0F9F8),
                              child: Icon(Icons.fingerprint_rounded, color: Color(0xFF0D6B6B)),
                            ),
                            activeThumbColor: const Color(0xFF0D8A7A),
                          ),
                        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom White Bar with Submit Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16232F) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D6B6B),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'التالي والبدء',
                                    style: GoogleFonts.cairo(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF333333),
      ),
    );
  }
}
