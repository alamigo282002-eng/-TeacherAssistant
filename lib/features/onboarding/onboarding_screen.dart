import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/widgets/app_scale_button.dart';
import '../auth/lock_provider.dart';
import '../settings/settings_provider.dart';
import '../shell/main_shell.dart';
import 'widgets/onboarding_pattern_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 1; 
  // Steps:
  // 1: Profile & Name
  // 2: Subjects (Single / Multiple mode)
  // 3: Setup Mode (Quick Default vs Custom Detailed)
  // 4: Theme, Font Scale & Bold
  // 5: Security & Optional Security Question
  // 6: Permissions (Auto-requested on enter)
  // 7: WhatsApp Community (جروب معلمي مصر)
  // 8: Features Showcase & Final Finish
  final int _totalSteps = 8;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _customSubjectController = TextEditingController();
  final TextEditingController _securityAnswerController = TextEditingController();
  final TextEditingController _customSecurityQuestionController = TextEditingController();

  final _step1FormKey = GlobalKey<FormState>();

  // Step 2: Subjects
  bool _isSingleSubjectMode = true; // Default: Single subject mode
  List<String> _selectedSubjects = ['اللغة العربية'];

  // Step 3: Setup Mode
  String _setupMode = 'custom'; // 'default' or 'custom'

  // Step 4: Theme Mode & Font
  bool _isDarkSelected = true;
  bool _isBoldSelected = false;
  bool _isExamModeSelected = false;
  double _selectedFontScale = 1.0;

  // Step 5: Security & Lock
  bool _enableLock = false;
  bool _enableBiometric = true;
  bool _enableSecurityQuestion = false;
  String _selectedSecurityQuestion = 'ما هو اسم أول مدرسة عملت بها؟';
  final List<String> _presetSecurityQuestions = [
    'ما هو اسم أول مدرسة عملت بها؟',
    'ما هي مادتك المفضلة أثناء دراستك؟',
    'ما هو اسم مدينتك المفضلة أو مسقط رأسك؟',
    'ما هو اسم المعلم أو الأستاذ المفضل لديك في صغرك؟',
    'سؤال مخصص...',
  ];

  // Step 6: Permissions Live Checkmarks (✓)
  bool _notifGranted = false;
  bool _alarmGranted = false;
  bool _contactsGranted = false;
  bool _hasRequestedPermissionsInStep = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    if (settings.teacherName != 'المعلم' && settings.teacherName.isNotEmpty) {
      _nameController.text = settings.teacherName;
    }
    if (settings.teacherPhone.isNotEmpty) {
      _phoneController.text = settings.teacherPhone;
    }
    if (settings.onboardingDone && settings.mySubjects.isNotEmpty) {
      _selectedSubjects = List.from(settings.mySubjects);
      _isSingleSubjectMode = _selectedSubjects.length <= 1;
    } else {
      _selectedSubjects = ['اللغة العربية'];
      _isSingleSubjectMode = true;
    }

    _isDarkSelected = settings.darkMode;
    _isBoldSelected = settings.boldFont;
    _isExamModeSelected = settings.examMode;
    _selectedFontScale = settings.fontScale;

    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    try {
      final notifStatus = await Permission.notification.status;
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      final contactsStatus = await FlutterContacts.requestPermission(readonly: true);
      if (mounted) {
        setState(() {
          _notifGranted = notifStatus.isGranted;
          _alarmGranted = alarmStatus.isGranted;
          _contactsGranted = contactsStatus;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _customSubjectController.dispose();
    _securityAnswerController.dispose();
    _customSecurityQuestionController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_step1FormKey.currentState?.validate() ?? false) {
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      if (_selectedSubjects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ يرجى اختيار مادة دراسية واحدة على الأقل للمتابعة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.red,
          ),
        );
        return;
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      if (_setupMode == 'default') {
        // Fast start: skip to WhatsApp Community (Step 7) or finish
        setState(() => _currentStep = 7);
      } else {
        setState(() => _currentStep = 4);
      }
    } else if (_currentStep == 5) {
      // Transitioning to Step 6: Permissions -> auto request permissions
      setState(() {
        _currentStep = 6;
      });
      if (!_hasRequestedPermissionsInStep) {
        _hasRequestedPermissionsInStep = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _requestAllPermissions();
        });
      }
    } else if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
      if (_currentStep == 6 && !_hasRequestedPermissionsInStep) {
        _hasRequestedPermissionsInStep = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _requestAllPermissions();
        });
      }
    } else {
      _finishOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep == 7 && _setupMode == 'default') {
      setState(() => _currentStep = 3);
    } else if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _requestAllPermissions() async {
    // 1. General Notifications
    try {
      final notifResult = await NotificationService().requestNotificationPermission();
      try {
        await Permission.notification.request();
      } catch (_) {}
      if (mounted) setState(() => _notifGranted = notifResult ?? true);
    } catch (_) {
      if (mounted) setState(() => _notifGranted = true);
    }

    // 2. Exact Alarm & Reminders
    try {
      final alarmResult = await NotificationService().requestExactAlarmPermission();
      try {
        final status = await Permission.scheduleExactAlarm.request();
        if (mounted) setState(() => _alarmGranted = status.isGranted || (alarmResult ?? true));
      } catch (_) {
        if (mounted) setState(() => _alarmGranted = alarmResult ?? true);
      }
    } catch (_) {
      if (mounted) setState(() => _alarmGranted = true);
    }

    // 3. Contacts
    try {
      final contactsResult = await FlutterContacts.requestPermission();
      if (mounted) setState(() => _contactsGranted = contactsResult);
    } catch (_) {
      if (mounted) setState(() => _contactsGranted = true);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم طلب وتفعيل الصلاحيات بنجاح!', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openWhatsAppCommunity() async {
    final uri = Uri.parse('https://chat.whatsapp.com/invite');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('سيتم تفعيل رابط انضمام جروب معلمي مصر قريباً 🇪🇬', style: GoogleFonts.tajawal()),
          ),
        );
      }
    }
  }

  Future<void> _finishOnboarding() async {
    final rawName = _nameController.text.trim();
    final name = rawName.isNotEmpty ? rawName : 'المعلم';
    final phone = _phoneController.text.trim();

    // Secret phone: auto-enable exam mode
    final isSecretPhone = phone == '123321123';
    if (isSecretPhone) _isExamModeSelected = true;

    final settings = context.read<SettingsProvider>();
    final lockP = context.read<LockProvider>();

    // 1. Save theme, font scale & font preference
    if (_isExamModeSelected) {
      await settings.setAppThemeMode('exam');
    } else if (_isDarkSelected) {
      await settings.setAppThemeMode('dark');
    } else {
      await settings.setAppThemeMode('light');
    }
    await settings.setBoldFont(_isBoldSelected);
    await settings.setFontScale(_selectedFontScale);

    // 2. Save Date Format to Gregorian
    await settings.setDateFormatType('gregorian');

    // 3. Save Security Lock & PIN & Security Question if chosen
    if (_enableLock && _pinController.text.trim().length >= 4) {
      String? secQuestion;
      String? secAnswer;
      if (_enableSecurityQuestion) {
        secQuestion = _selectedSecurityQuestion == 'سؤال مخصص...'
            ? _customSecurityQuestionController.text.trim()
            : _selectedSecurityQuestion;
        secAnswer = _securityAnswerController.text.trim();
      }

      await lockP.enableLock(
        pin: _pinController.text.trim(),
        useBiometric: _enableBiometric,
        securityQuestion: (secQuestion != null && secQuestion.isNotEmpty) ? secQuestion : null,
        securityAnswer: (secAnswer != null && secAnswer.isNotEmpty) ? secAnswer : null,
      );
    }

    // 4. Complete Onboarding
    await settings.completeOnboarding(
      name: name,
      phone: phone,
      subjects: _selectedSubjects,
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  OnboardingStepType _getStepType(int step) {
    switch (step) {
      case 1:
        return OnboardingStepType.profile;
      case 2:
        return OnboardingStepType.subjects;
      case 3:
        return OnboardingStepType.setupMode;
      case 4:
        return OnboardingStepType.themeFont;
      case 5:
        return OnboardingStepType.security;
      case 6:
        return OnboardingStepType.permissions;
      case 7:
        return OnboardingStepType.community;
      case 8:
      default:
        return OnboardingStepType.features;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkSelected;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF3F7F5),
      body: OnboardingPatternBackground(
        stepType: _getStepType(_currentStep),
        isDark: isDark,
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Step Indicator Pills
                    Row(
                      children: List.generate(_totalSteps, (index) {
                        final stepNum = index + 1;
                        final isActive = stepNum == _currentStep;
                        final isPast = stepNum < _currentStep;
                        final color = isDark ? AppColors.darkPrimary : AppColors.primary;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: isActive ? 22 : 6,
                          height: 7,
                          decoration: BoxDecoration(
                            color: (isActive || isPast)
                                ? color
                                : (isDark ? const Color(0xFF2E3E34) : const Color(0xFFD1DDD6)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    // Back button
                    if (_currentStep > 1)
                      IconButton(
                        icon: Icon(
                          Icons.arrow_forward_rounded, // Points right in RTL
                          color: isDark ? Colors.white70 : AppColors.ink,
                        ),
                        tooltip: 'الخطوة السابقة',
                        onPressed: _previousStep,
                      )
                    else
                      const SizedBox(width: 48, height: 48),
                  ],
                ),
              ),

              // Scrollable Active Step
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(_currentStep),
                          child: _buildCurrentStep(isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Unified Fixed Bottom Bar
              _buildUnifiedBottomBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Profile(isDark);
      case 2:
        return _buildStep2Subjects(isDark);
      case 3:
        return _buildStep3SetupMode(isDark);
      case 4:
        return _buildStep4ThemeAndFont(isDark);
      case 5:
        return _buildStep5Security(isDark);
      case 6:
        return _buildStep6Permissions(isDark);
      case 7:
        return _buildStep7EgyptCommunity(isDark);
      case 8:
      default:
        return _buildStep8FeaturesShowcase(isDark);
    }
  }

  // =============================================================
  // STEP 1: Profile & User Agreement
  // =============================================================
  Widget _buildStep1Profile(bool isDark) {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 6),
          // Heading with line height and padding to ensure no clipping on 'المُعلِّم'
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              'مرحباً بك في مُساعِد المُعلِّم',
              textAlign: TextAlign.center,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: true,
                applyHeightToLastDescent: true,
              ),
              style: GoogleFonts.changa(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.35,
                color: isDark ? const Color(0xFFF8FAFC) : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'المنظومة الاحترافية لإدارة الحصص، رصد الحضور، تسجيل الدرجات، والمتابعة المالية بكل سهولة.',
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              fontSize: 13.5,
              color: isDark ? AppColors.darkMuted : const Color(0xFF334155),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.15),
                    child: Icon(Icons.school_rounded, size: 36, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                  ),
                ),
                const SizedBox(height: 18),

                // Name Input - High contrast, Dark & Bold
                Text(
                  'اسم الأستاذ / المعلم *',
                  style: GoogleFonts.tajawal(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.tajawal(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'مثال: أ. أحمد مصطفى',
                    hintStyle: GoogleFonts.tajawal(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                    prefixIcon: Icon(Icons.badge_outlined, color: isDark ? AppColors.darkPrimary : AppColors.primary, size: 22),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.darkPrimary : AppColors.primary, width: 1.8),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى كتابة اسم المعلم' : null,
                ),
                const SizedBox(height: 16),

                // WhatsApp Phone Input - High contrast, Dark & Bold
                Text(
                  'رقم هاتف الواتساب (اختياري)',
                  style: GoogleFonts.tajawal(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.changa(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '01xxxxxxxxx',
                    hintStyle: GoogleFonts.changa(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                    prefixIcon: Icon(Icons.phone_outlined, color: isDark ? AppColors.darkPrimary : AppColors.primary, size: 22),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.darkPrimary : AppColors.primary, width: 1.8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // User Agreement & Terms Notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.tajawal(
                            fontSize: 12.5,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                          children: const [
                            TextSpan(text: 'عند الضغط على '),
                            TextSpan(
                              text: '«التالي»',
                              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                            ),
                            TextSpan(
                              text: ' فإنك توافق على اتفاقية المستخدم وسياسة الخصوصية. جميع بياناتك تُحفظ محلياً 100% على جهازك ولا نجمع أي بيانات خارجية.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _showUserAgreementDialog(isDark),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF0D7377)),
                    label: Text(
                      'عرض بنود الاتفاقية وإخلاء المسؤولية 📄',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D7377),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserAgreementDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'اتفاقية المستخدم والخصوصية',
              style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAgreementItem(
                icon: Icons.storage_rounded,
                title: 'بياناتك محلية ١٠٠٪ (Offline)',
                desc: 'جميع سجلات الطلاب، الحضور، الدرجات، والماليات تُحفظ بالكامل داخل قاعدة بيانات هاتفك فقط، ولا يتم إرسالها إلى أي خوادم سحابية.',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildAgreementItem(
                icon: Icons.privacy_tip_rounded,
                title: 'حماية الخصوصية المطلقة',
                desc: 'التطبيق لا يجمع أو يتتبع أو يبيع أي بيانات شخصية، جهات اتصال، أو سجلات محادثات واتساب إطلاقاً.',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildAgreementItem(
                icon: Icons.backup_rounded,
                title: 'إخلاء المسؤولية والنسخ الاحتياطي',
                desc: 'المستخدم مسؤول مسؤولية تامة عن إنشاء وحفظ نسخ احتياطية دورية عبر قسم الإعدادات. لا يتحمل المطور أي مسؤولية عن فقدان أو تلف البيانات الناتج عن فرمتة الجهاز أو تلف الهاتف.',
                isDark: isDark,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('موافق وفهمت ذلك', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementItem({
    required IconData icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.tajawal(
                  fontSize: 11.5,
                  color: isDark ? AppColors.darkMuted : AppColors.muted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =============================================================
  // STEP 2: Subjects Selection (Single vs Multiple Mode)
  // =============================================================
  Widget _buildStep2Subjects(bool isDark) {
    final allAvailable = [
      ...AppConstants.defaultSubjects,
      ..._selectedSubjects.where((s) => !AppConstants.defaultSubjects.contains(s)),
    ];

    final primaryCol = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        Text(
          'ما هي المواد التي تُدرّسها؟ 📚',
          textAlign: TextAlign.center,
          style: GoogleFonts.changa(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF8FAFC) : AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'اختر مادة واحدة أو أكثر لتخصيص مجموعاتك وامتحاناتك وتقاريرك تلقائياً.',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 13.5,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),

        // Mode Switcher: Single Subject (Default) vs Multiple Subjects
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : const Color(0xFFE2E8E4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              // Single Subject Mode (Default)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSingleSubjectMode = true;
                      if (_selectedSubjects.length > 1) {
                        _selectedSubjects = [_selectedSubjects.first];
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isSingleSubjectMode
                          ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSingleSubjectMode ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          size: 16,
                          color: _isSingleSubjectMode
                              ? (isDark ? AppColors.darkBg : Colors.white)
                              : (isDark ? Colors.white70 : AppColors.ink),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'مادة واحدة (افتراضي)',
                          style: GoogleFonts.tajawal(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: _isSingleSubjectMode
                                ? (isDark ? AppColors.darkBg : Colors.white)
                                : (isDark ? Colors.white70 : AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Multiple Subjects Mode
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSingleSubjectMode = false;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isSingleSubjectMode
                          ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          !_isSingleSubjectMode ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 16,
                          color: !_isSingleSubjectMode
                              ? (isDark ? AppColors.darkBg : Colors.white)
                              : (isDark ? Colors.white70 : AppColors.ink),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'مواد متعددة',
                          style: GoogleFonts.tajawal(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: !_isSingleSubjectMode
                                ? (isDark ? AppColors.darkBg : Colors.white)
                                : (isDark ? Colors.white70 : AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Subjects Grid Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories_rounded, size: 18, color: primaryCol),
                      const SizedBox(width: 8),
                      Text(
                        _isSingleSubjectMode ? 'اختر مادتك الأساسية' : 'اختر المواد التي تدرّسها',
                        style: GoogleFonts.changa(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryCol.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${ArabicNumbers.convert(_selectedSubjects.length)} مختارة',
                      style: GoogleFonts.tajawal(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: primaryCol,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allAvailable.map((subject) {
                  final isSelected = _selectedSubjects.contains(subject);
                  return FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (_isSingleSubjectMode) {
                          // Single mode: select only this subject
                          _selectedSubjects = [subject];
                        } else {
                          // Multi mode: toggle
                          if (selected) {
                            _selectedSubjects.add(subject);
                          } else {
                            if (_selectedSubjects.length > 1) {
                              _selectedSubjects.remove(subject);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('يجب اختيار مادة واحدة على الأقل', style: GoogleFonts.tajawal()),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        }
                      });
                    },
                    selectedColor: primaryCol,
                    checkmarkColor: isDark ? AppColors.darkBg : Colors.white,
                    backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F2),
                    labelStyle: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? AppColors.darkBg : Colors.white)
                          : (isDark ? AppColors.darkText : Colors.black87),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? primaryCol
                            : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8E4)),
                        width: isSelected ? 1.5 : 0.8,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Add custom subject row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customSubjectController,
                      style: GoogleFonts.tajawal(fontSize: 13.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'أدخل مادة أخرى مخصصة...',
                        hintStyle: GoogleFonts.tajawal(fontSize: 12, color: isDark ? AppColors.darkMuted : Colors.black38),
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFA),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      final val = _customSubjectController.text.trim();
                      if (val.isNotEmpty && !_selectedSubjects.contains(val)) {
                        setState(() {
                          if (_isSingleSubjectMode) {
                            _selectedSubjects = [val];
                          } else {
                            _selectedSubjects.add(val);
                          }
                          _customSubjectController.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryCol,
                      foregroundColor: isDark ? AppColors.darkBg : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      'إضافة',
                      style: GoogleFonts.changa(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =============================================================
  // STEP 3: Setup Mode (Dedicated Page - Quick Default vs Custom)
  // =============================================================
  Widget _buildStep3SetupMode(bool isDark) {
    final primaryCol = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        Text(
          'كيف تود بدء الاستخدام؟ 🚀',
          textAlign: TextAlign.center,
          style: GoogleFonts.changa(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF8FAFC) : AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'اختر الطريقة التي تفضلها لبدء استخدام المنظومة، ثم اضغط «التالي» للمتابعة.',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 13.5,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),

        // Option 1: Quick Default Setup (No Gradients)
        GestureDetector(
          onTap: () => setState(() => _setupMode = 'default'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? (_setupMode == 'default' ? const Color(0xFF1E3327) : AppColors.darkCard)
                  : (_setupMode == 'default' ? const Color(0xFFECFDF5) : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _setupMode == 'default' ? primaryCol : (isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                width: _setupMode == 'default' ? 2.2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _setupMode == 'default'
                      ? primaryCol.withValues(alpha: isDark ? 0.25 : 0.15)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryCol.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.bolt_rounded, color: primaryCol, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الاستمرار بالإعدادات الافتراضية ⚡',
                            style: GoogleFonts.changa(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.ink,
                            ),
                          ),
                          Text(
                            'بدء سريع ومباشر بأفضل الخيارات الموصى بها',
                            style: GoogleFonts.tajawal(
                              fontSize: 11.5,
                              color: isDark ? AppColors.darkMuted : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _setupMode == 'default' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: _setupMode == 'default' ? primaryCol : (isDark ? AppColors.darkMuted : Colors.grey),
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Text(
                  'تطبيق الإعدادات القياسية تلقائياً، تخطي خطوات القفل وتخصيص المظهر الآن، والانتقال فوراً للبدء في إضافة المجموعات والطلاب. يمكنك تعديل أي إعداد لاحقاً في أي وقت من شاشة الإعدادات.',
                  style: GoogleFonts.tajawal(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildFeaturePill('⚡ تشغيل مباشر', primaryCol, isDark),
                    _buildFeaturePill('⚙️ إعدادات قياسية', primaryCol, isDark),
                    _buildFeaturePill('⏱️ توفير الوقت', primaryCol, isDark),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Option 2: Detailed Customization (No Gradients)
        GestureDetector(
          onTap: () => setState(() => _setupMode = 'custom'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? (_setupMode == 'custom' ? const Color(0xFF1E3327) : AppColors.darkCard)
                  : (_setupMode == 'custom' ? const Color(0xFFECFDF5) : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _setupMode == 'custom' ? primaryCol : (isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                width: _setupMode == 'custom' ? 2.2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _setupMode == 'custom'
                      ? primaryCol.withValues(alpha: isDark ? 0.25 : 0.15)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D7377).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Color(0xFF0D7377), size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تخصيص الإعدادات بالتفصيل 🛠️',
                            style: GoogleFonts.changa(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.ink,
                            ),
                          ),
                          Text(
                            'ضبط المظهر وحجم الخط، الأمان، والصلاحيات',
                            style: GoogleFonts.tajawal(
                              fontSize: 11.5,
                              color: isDark ? AppColors.darkMuted : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _setupMode == 'custom' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: _setupMode == 'custom' ? primaryCol : (isDark ? AppColors.darkMuted : Colors.grey),
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Text(
                  'المرور على خطوات التخصيص خطوة بخطوة: اختيار المظهر (داكن/فاتح)، حجم الخط، قفل الشاشة برمز PIN وسؤال الأمان، وتفعيل صلاحيات التنبيهات والمنبه الدقيق، والانضمام لمجتمع المعلمين.',
                  style: GoogleFonts.tajawal(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildFeaturePill('🎨 المظهر والخط', const Color(0xFF0D7377), isDark),
                    _buildFeaturePill('🔒 أمان وPIN', const Color(0xFF0D7377), isDark),
                    _buildFeaturePill('🔔 الصلاحيات', const Color(0xFF0D7377), isDark),
                    _buildFeaturePill('💬 مجتمع المعلمين', const Color(0xFF0D7377), isDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturePill(String text, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.tajawal(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : color,
        ),
      ),
    );
  }

  // =============================================================
  // STEP 4: Theme Selection & Font Scale
  // =============================================================
  Widget _buildStep4ThemeAndFont(bool isDark) {
    final primaryCol = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        Text(
          'المظهر وحجم الخط ✨',
          textAlign: TextAlign.center,
          style: GoogleFonts.changa(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF8FAFC) : AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'خصص مظهر التطبيق وحجم الخط المناسب لعينيك لتجربة استخدام مريحة.',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 13.5,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),

        // Dark Mode Option Card
        GestureDetector(
          onTap: () {
            setState(() {
              _isDarkSelected = true;
              _isExamModeSelected = false;
            });
            context.read<SettingsProvider>().setAppThemeMode('dark');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF121A15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (_isDarkSelected && !_isExamModeSelected) ? AppColors.darkPrimary : const Color(0xFF24382D),
                width: (_isDarkSelected && !_isExamModeSelected) ? 2.2 : 1.0,
              ),
              boxShadow: [
                if (_isDarkSelected && !_isExamModeSelected)
                  BoxShadow(
                    color: AppColors.darkPrimary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2E25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.dark_mode_rounded, color: AppColors.darkPrimary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الوضع الداكن (Dark Mode) 🌙',
                        style: GoogleFonts.changa(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'خلفية ليلية زمردية عميقة ومريحة للعين',
                        style: GoogleFonts.tajawal(fontSize: 11.5, color: AppColors.darkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  (_isDarkSelected && !_isExamModeSelected) ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: (_isDarkSelected && !_isExamModeSelected) ? AppColors.darkPrimary : AppColors.darkMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Light Mode Option Card
        GestureDetector(
          onTap: () {
            setState(() {
              _isDarkSelected = false;
              _isExamModeSelected = false;
            });
            context.read<SettingsProvider>().setAppThemeMode('light');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (!_isDarkSelected && !_isExamModeSelected) ? AppColors.primary : const Color(0xFFCBD5E1),
                width: (!_isDarkSelected && !_isExamModeSelected) ? 2.2 : 1.0,
              ),
              boxShadow: [
                if (!_isDarkSelected && !_isExamModeSelected)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.light_mode_rounded, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الوضع الفاتح (Light Mode) 🌞',
                        style: GoogleFonts.changa(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'خلفية ناصعة أنيقة بنقاء الزمرد والغابات',
                        style: GoogleFonts.tajawal(fontSize: 11.5, color: const Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                Icon(
                  (!_isDarkSelected && !_isExamModeSelected) ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: (!_isDarkSelected && !_isExamModeSelected) ? AppColors.primary : Colors.grey,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Exam Mode Option Card
        GestureDetector(
          onTap: () {
            setState(() {
              _isExamModeSelected = !_isExamModeSelected;
              if (_isExamModeSelected) _isDarkSelected = true;
            });
            context.read<SettingsProvider>().setAppThemeMode(_isExamModeSelected ? 'exam' : (_isDarkSelected ? 'dark' : 'light'));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: _isExamModeSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF050C0E), Color(0xFF0D2320), Color(0xFF001A17)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    )
                  : null,
              color: _isExamModeSelected ? null : (isDark ? const Color(0xFF121A15) : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isExamModeSelected
                    ? const Color(0xFF00E5CC)
                    : (isDark ? const Color(0xFF24382D) : const Color(0xFFCBD5E1)),
                width: _isExamModeSelected ? 2.0 : 1.0,
              ),
              boxShadow: _isExamModeSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00E5CC).withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isExamModeSelected
                        ? const Color(0xFF00E5CC).withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF1F2E25) : const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(14),
                    border: _isExamModeSelected
                        ? Border.all(color: const Color(0xFF00E5CC).withValues(alpha: 0.5))
                        : null,
                  ),
                  child: Icon(
                    Icons.science_rounded,
                    color: _isExamModeSelected ? const Color(0xFF00E5CC) : (isDark ? AppColors.darkMuted : Colors.grey),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'وضع الاختبار 🧪',
                            style: GoogleFonts.changa(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: _isExamModeSelected
                                  ? const Color(0xFF00E5CC)
                                  : (isDark ? Colors.white70 : AppColors.muted),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5CC), Color(0xFFFFC84A)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'مميز',
                              style: GoogleFonts.tajawal(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF050C0E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'أسود فضائي عميق · نيون تيل كهربائي · ذهبي كهرماني',
                        style: GoogleFonts.tajawal(
                          fontSize: 11.5,
                          color: _isExamModeSelected
                              ? const Color(0xFF6B9E9A)
                              : (isDark ? AppColors.darkMuted : AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExamModeSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: _isExamModeSelected ? const Color(0xFF00E5CC) : (isDark ? AppColors.darkMuted : Colors.grey),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Font Scale Selection Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: primaryCol.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.format_size_rounded, color: primaryCol, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حجم الخط المفضل 🔍',
                          style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.ink),
                        ),
                        Text(
                          'اختر حجم النصوص المناسب للقراءة في جميع الشاشات',
                          style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Font Size Selector Pills
              Row(
                children: [
                  _buildFontScaleButton(label: 'عادي', scale: 0.95, isDark: isDark, primaryCol: primaryCol),
                  const SizedBox(width: 8),
                  _buildFontScaleButton(label: 'متوسط (افتراضي)', scale: 1.0, isDark: isDark, primaryCol: primaryCol),
                  const SizedBox(width: 8),
                  _buildFontScaleButton(label: 'كبير ومريح', scale: 1.15, isDark: isDark, primaryCol: primaryCol),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Bold Font Option Card
        GestureDetector(
          onTap: () {
            setState(() => _isBoldSelected = !_isBoldSelected);
            context.read<SettingsProvider>().setBoldFont(_isBoldSelected);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isBoldSelected ? primaryCol : (isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                width: _isBoldSelected ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryCol.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.format_bold_rounded, color: primaryCol, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'خط عريض مميز (Bold Font) ✍️',
                            style: GoogleFonts.changa(
                              fontSize: 14,
                              fontWeight: _isBoldSelected ? FontWeight.w900 : FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'يجعل جميع نصوص التطبيق بارزة وعريضة وواضحة جداً',
                            style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isBoldSelected,
                      activeThumbColor: primaryCol,
                      onChanged: (val) {
                        setState(() => _isBoldSelected = val);
                        context.read<SettingsProvider>().setBoldFont(val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Live Dynamic Preview Box
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryCol.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryCol.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_rounded, size: 16, color: primaryCol),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isBoldSelected
                              ? 'معاينة: مرحباً بك يا أستاذنا في مساعد المعلم 🌟'
                              : 'معاينة: مرحباً بك يا أستاذنا في مساعد المعلم ✨',
                          style: GoogleFonts.tajawal(
                            fontSize: 12.5 * _selectedFontScale,
                            fontWeight: _isBoldSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontScaleButton({
    required String label,
    required double scale,
    required bool isDark,
    required Color primaryCol,
  }) {
    final isSelected = (_selectedFontScale - scale).abs() < 0.05;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFontScale = scale);
          context.read<SettingsProvider>().setFontScale(scale);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryCol
                : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F2)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryCol : (isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? (isDark ? AppColors.darkBg : Colors.white)
                    : (isDark ? Colors.white70 : AppColors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // STEP 5: App Security (PIN & Optional Security Question)
  // =============================================================
  Widget _buildStep5Security(bool isDark) {
    final primaryCol = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        Text(
          'أمان التطبيق وقفل الشاشة 🔒',
          textAlign: TextAlign.center,
          style: GoogleFonts.changa(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF8FAFC) : AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'احمِ بيانات الطلاب وسجلاتك برمز PIN سريع وبصمة الإصبع عند فتح التطبيق.',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 13.5,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lock Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  _enableLock ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: primaryCol,
                  size: 26,
                ),
                title: Text(
                  'تفعيل قفل التطبيق',
                  style: GoogleFonts.changa(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _enableLock ? 'التطبيق محمي برمز PIN' : 'غير مفعل (دخول مباشر بدون قفل)',
                  style: GoogleFonts.tajawal(fontSize: 11.5, color: isDark ? AppColors.darkMuted : AppColors.muted),
                ),
                value: _enableLock,
                activeThumbColor: primaryCol,
                onChanged: (val) => setState(() => _enableLock = val),
              ),

              if (_enableLock) ...[
                const Divider(height: 20),
                const SizedBox(height: 4),

                // PIN input
                Text(
                  'أدخل رمز PIN المكون من 4 إلى 6 أرقام *',
                  style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  style: GoogleFonts.changa(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '••••',
                    hintStyle: GoogleFonts.changa(letterSpacing: 8, color: Colors.grey),
                    counterText: '',
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // Biometrics toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    Icons.fingerprint_rounded,
                    color: primaryCol,
                    size: 24,
                  ),
                  title: Text(
                    'فتح القفل ببصمة الإصبع أو الوجه',
                    style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  value: _enableBiometric,
                  activeThumbColor: primaryCol,
                  onChanged: (v) => setState(() => _enableBiometric = v),
                ),

                const Divider(height: 20),

                // Optional Security Question Toggle
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: primaryCol, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'إضافة سؤال أمان اختياري لاستعادة الرمز',
                        style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Checkbox(
                      value: _enableSecurityQuestion,
                      activeColor: primaryCol,
                      onChanged: (v) => setState(() => _enableSecurityQuestion = v ?? false),
                    ),
                  ],
                ),

                if (_enableSecurityQuestion) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryCol.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سؤال الأمان:',
                          style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkMuted : AppColors.muted),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSecurityQuestion,
                          isExpanded: true,
                          style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                          dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1))),
                          ),
                          items: _presetSecurityQuestions.map((q) {
                            return DropdownMenuItem<String>(
                              value: q,
                              child: Text(q, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSecurityQuestion = val);
                          },
                        ),
                        if (_selectedSecurityQuestion == 'سؤال مخصص...') ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customSecurityQuestionController,
                            style: GoogleFonts.tajawal(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              hintText: 'اكتب سؤال الأمان المخصص...',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          'إجابة سؤال الأمان:',
                          style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkMuted : AppColors.muted),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _securityAnswerController,
                          style: GoogleFonts.tajawal(fontSize: 13.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'أدخل الإجابة السرية...',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  // =============================================================
  // STEP 6: Permissions (Auto Requested upon Entry)
  // =============================================================
  Widget _buildStep6Permissions(bool isDark) {
    final primaryCol = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        Text(
          'الصلاحيات والتنبيهات 🔔',
          textAlign: TextAlign.center,
          style: GoogleFonts.changa(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF8FAFC) : AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'تم طلب الصلاحيات لضمان وصول منبه ومواعيد الحصص وإشعارات السداد في وقتها بدقة.',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 13.5,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),

        // 1. General Notification Permission Tile
        _buildPermissionCheckTile(
          title: 'الإشعارات العامة والتنبيهات',
          subtitle: 'إشعار تذكيري قبل الحصص وتنبيهات الغياب اليومي',
          icon: Icons.notifications_active_rounded,
          isGranted: _notifGranted,
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        // 2. Exact Alarm / المنبه الدقيق
        _buildPermissionCheckTile(
          title: 'صلاحية المنبه والتنبيهات الدقيقة ⏰',
          subtitle: 'لضمان إطلاق المنبه في الموعد المحدد للحصة بدقة فائقة',
          icon: Icons.alarm_on_rounded,
          isGranted: _alarmGranted,
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        // 3. Contacts Permission Tile
        _buildPermissionCheckTile(
          title: 'جهات اتصال الطلاب وأولياء الأمور',
          subtitle: 'استيراد أرقام الهواتف وإرسال رسائل الواتساب بنقرة واحدة',
          icon: Icons.contacts_rounded,
          isGranted: _contactsGranted,
          isDark: isDark,
        ),

        const SizedBox(height: 18),

        // Re-request / Grant Button
        AppScaleButton(
          onTap: _requestAllPermissions,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2E25) : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryCol),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_rounded, color: primaryCol, size: 18),
                const SizedBox(width: 8),
                Text(
                  'إعادة طلب وتفعيل جميع الصلاحيات',
                  style: GoogleFonts.changa(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: primaryCol,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionCheckTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isGranted,
    required bool isDark,
  }) {
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isGranted ? activeColor : (isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: (isGranted ? activeColor : Colors.grey).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isGranted ? activeColor : Colors.grey, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.changa(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isGranted ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGranted) ...[
                  Icon(Icons.check_rounded, color: activeColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'مفعل',
                    style: GoogleFonts.tajawal(fontSize: 10.5, fontWeight: FontWeight.bold, color: activeColor),
                  ),
                ] else ...[
                  const Icon(Icons.circle_outlined, color: Colors.grey, size: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // STEP 7: Egypt Teachers WhatsApp Community (جروب معلمي مصر 🇪🇬)
  // =============================================================
  Widget _buildStep7EgyptCommunity(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        Text(
          'جروب معلمي مصر 🇪🇬',
          textAlign: TextAlign.center,
          style: GoogleFonts.changa(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF8FAFC) : AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'انضم لأكبر مجتمع تفاعلي يضم نخبة من معلمي ومدرسي مصر لتبادل المذكرات، التجارب، والدعم الفني المباشر.',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 13.5,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.forum_rounded, size: 48, color: Color(0xFF25D366)),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'جروب معلمي مصر الرسمي 🇪🇬',
                    style: GoogleFonts.changa(fontSize: 16.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'ملتقى المعلمين على واتساب للتطوير والمتابعة المستمرة',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.muted),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Benefits
              _buildCommunityBenefitRow(Icons.bolt_rounded, 'تحديثات وميزات حصرية للتطبيق أولاً بأول', isDark),
              const SizedBox(height: 10),
              _buildCommunityBenefitRow(Icons.support_agent_rounded, 'دعم فني واستفسارات مباشرة ومجانية للمدرسين', isDark),
              const SizedBox(height: 10),
              _buildCommunityBenefitRow(Icons.menu_book_rounded, 'تبادل الأفكار والنماذج لتطوير إدارة الحصص', isDark),

              const SizedBox(height: 20),

              // Join WhatsApp Button
              AppScaleButton(
                onTap: _openWhatsAppCommunity,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'انضمام لجروب معلمي مصر الآن 🚀',
                        style: GoogleFonts.changa(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityBenefitRow(IconData icon, String label, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF25D366)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // STEP 8: Features Showcase & Final Finish
  // =============================================================
  Widget _buildStep8FeaturesShowcase(bool isDark) {
    Widget featureCard({
      required IconData icon,
      required String title,
      required String badgeText,
      required String desc,
      required Color iconColor,
      required Color badgeBg,
      required Color badgeTextCol,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.changa(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.tajawal(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: badgeTextCol,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: GoogleFonts.tajawal(
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        Text(
          'أنت الآن جاهز للانطلاق! 🚀',
          textAlign: TextAlign.center,
          style: GoogleFonts.changa(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF8FAFC) : AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'مُساعِد المُعلِّم يضع بين يديك منظومة احترافية ذكية ومتكاملة لإدارة حصصك وطلابك بكل سهولة.',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 13.5,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),

        // Feature 1: Attendance
        featureCard(
          icon: Icons.fact_check_rounded,
          title: 'رصد الحضور الذكي والغياب',
          badgeText: 'تحضير ذكي',
          desc: 'سحب الكروت يميناً ويساراً، الرصد السريع بالشبكة، وإرسال إشعار غياب فوري لولي الأمر.',
          iconColor: const Color(0xFF0D7377),
          badgeBg: const Color(0xFF14B8A6).withValues(alpha: 0.15),
          badgeTextCol: const Color(0xFF0D7377),
        ),

        // Feature 2: Finance
        featureCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'الإدارة المالية والاشتراكات',
          badgeText: 'دفع شهري وحصص',
          desc: 'متابعة الاشتراكات الشهرية والحصص، نسب التحصيل، إعفاءات الحالات الخاصة، وخصومات الأخوة.',
          iconColor: const Color(0xFFF59E0B),
          badgeBg: const Color(0xFFF59E0B).withValues(alpha: 0.15),
          badgeTextCol: const Color(0xFFD97706),
        ),

        // Feature 3: Exams & Honor Board
        featureCard(
          icon: Icons.emoji_events_rounded,
          title: 'الامتحانات ولوحة الشرف',
          badgeText: 'ترتيب الأوائل',
          desc: 'رصد الدرجات، تحليل المستوى، ولوحة شرف تفاعلية لتكريم الطلاب المتميزين ونشرها.',
          iconColor: const Color(0xFF8B5CF6),
          badgeBg: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          badgeTextCol: const Color(0xFF7C3AED),
        ),

        // Feature 4: Certificates
        featureCard(
          icon: Icons.military_tech_rounded,
          title: 'مصمم ومحرر الشهادات',
          badgeText: 'شهادات VIP',
          desc: 'تعديل وتخصيص شهادات التقدير مباشرة بالنقر على النصوص ومشاركتها عبر الواتساب.',
          iconColor: const Color(0xFF10B981),
          badgeBg: const Color(0xFF10B981).withValues(alpha: 0.15),
          badgeTextCol: const Color(0xFF059669),
        ),

        // Feature 5: WhatsApp Assistant
        featureCard(
          icon: Icons.chat_rounded,
          title: 'مساعد الواتساب الفوري',
          badgeText: 'إرسال بنقرة',
          desc: 'قوالب رسائل ذكية قابلة للتعديل بالكامل للغياب، الدرجات، التذكير بالدفع، وإلغاء الحصص.',
          iconColor: const Color(0xFF25D366),
          badgeBg: const Color(0xFF25D366).withValues(alpha: 0.15),
          badgeTextCol: const Color(0xFF16A34A),
        ),

        // Feature 6: Local & Privacy
        featureCard(
          icon: Icons.shield_rounded,
          title: 'أمان وخصوصية محلية ١٠٠٪',
          badgeText: 'Offline-First',
          desc: 'بياناتك محفوظة بأمان على هاتفك فقط دون اتصال بالإنترنت مع حماية بالقفل والبصمة.',
          iconColor: const Color(0xFF0284C7),
          badgeBg: const Color(0xFF0284C7).withValues(alpha: 0.15),
          badgeTextCol: const Color(0xFF0284C7),
        ),
      ],
    );
  }

  // =============================================================
  // UNIFIED BOTTOM NAVIGATION BAR
  // =============================================================
  Widget _buildUnifiedBottomBar(bool isDark) {
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final isLastStep = _currentStep == _totalSteps;
    final isStep2Empty = _currentStep == 2 && _selectedSubjects.isEmpty;

    final buttonColor = isStep2Empty
        ? (isDark ? const Color(0xFF24382D) : const Color(0xFFCBD5E1))
        : activeColor;
    final buttonTextColor = isStep2Empty
        ? (isDark ? Colors.white38 : Colors.black38)
        : (isDark ? Colors.black : Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Step Counter Text
          Text(
            'الخطوة ${ArabicNumbers.convert(_currentStep)} من ${ArabicNumbers.convert(_totalSteps)}',
            style: GoogleFonts.tajawal(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),

          // Action Button: "التالي" or "بدء استخدام التطبيق 🚀"
          AppScaleButton(
            onTap: isStep2Empty ? null : _nextStep,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isStep2Empty
                    ? null
                    : [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLastStep ? 'بدء استخدام التطبيق 🚀' : 'التالي',
                    style: GoogleFonts.changa(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: buttonTextColor,
                    ),
                  ),
                  if (!isLastStep) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_back_rounded, // Left arrow in RTL
                      color: buttonTextColor,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
