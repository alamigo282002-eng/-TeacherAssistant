import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/group_model.dart';
import '../../data/models/student_model.dart';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _initialized = false;

  String _teacherName = 'المعلم';
  String _teacherPhone = '';
  List<String> _mySubjects = [];
  bool _darkMode = false;
  bool _notifSession = true;
  bool _notifAbsence = true;
  bool _notifPayment = true;
  bool _notifExam = true;
  int _paymentReminderDay = 5;
  int _sessionReminderMinutes = 10;
  bool _onboardingDone = false;
  bool _notificationsEnabled = true;
  bool _attendanceAutoOpened = false;
  bool _developerMode = false;
  String _lastError = '';
  String _defaultContactMethod = 'ask'; // ask, student, parent
  String _defaultPaymentMode = 'monthly'; // monthly, per_session
  bool _folderCardStyle = false;
  String _studentCardStyle = 'modern'; // modern, folder, elevated3d, compact, minimal
  String _groupCardStyle = 'classic'; // classic, banner, folder, compactGrid
  String _attendanceMode = 'list'; // list, cardSwipe, quickGrid, rollCall, bulk
  String _dateFormatType = 'both'; // both, hijri, gregorian
  bool _biometricEnabled = false;
  String _notifSound = 'bell'; // 'bell', 'gentle', 'school', 'vibrate_only', 'default'

  String _templateAbsence = 'السلام عليكم، نود إبلاغكم بأن الطالب {student} غاب النهاردة عن حصة {group} بتاريخ {date}.';
  String _templatePayment = 'السلام عليكم، نود تذكيركم بتسديد اشتراك شهر {month} للطالب {student}.';
  String _templateExam = 'السلام عليكم، جاب {student} {mark} من {total} في اختبار {exam}.';
  String _templateCancelSession = 'السلام عليكم ورحمة الله، نود إبلاغكم بإلغاء حصة {group} بتاريخ {date}. {compensation}';
  String _templateWelcome = 'أهلاً بك يا {student} في مجموعة {group} مع الأستاذ {teacher}. نتمنى لك تفوقاً دائماً 🌟';
  String _templateGeneralNote = 'السلام عليكم، رسالة هامة بخصوص الطالب {student}: {note}';
  bool _examMode = false;
  double _fontScale = 1.0; // 0.85, 1.0, 1.15, 1.25

  String get teacherName => _teacherName;
  String get teacherPhone => _teacherPhone;
  List<String> get mySubjects => _mySubjects;
  List<String> get teacherSpecialties => _mySubjects; // alias for backwards compatibility
  bool get darkMode => _darkMode;
  double get fontScale => _fontScale;
  bool get notifSession => _notifSession;
  bool get notifAbsence => _notifAbsence;
  bool get notifPayment => _notifPayment;
  bool get notifExam => _notifExam;
  int get paymentReminderDay => _paymentReminderDay;
  int get sessionReminderMinutes => _sessionReminderMinutes;
  bool get onboardingDone => _onboardingDone;
  bool get initialized => _initialized;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get attendanceAutoOpened => _attendanceAutoOpened;
  bool get developerMode => _developerMode;
  String get lastError => _lastError;
  String get defaultContactMethod => _defaultContactMethod;
  String get defaultPaymentMode => _defaultPaymentMode;
  bool get defaultContactMethodAsk => _defaultContactMethod == 'ask';
  bool get folderCardStyle => _folderCardStyle;
  String get studentCardStyle => _studentCardStyle;
  String get groupCardStyle => _groupCardStyle;
  String get attendanceMode => _attendanceMode;
  String get dateFormatType => _dateFormatType;
  bool get biometricEnabled => _biometricEnabled;
  String get notifSound => _notifSound;

  String get templateAbsence => _templateAbsence;
  String get templatePayment => _templatePayment;
  String get templateExam => _templateExam;
  String get templateCancelSession => _templateCancelSession;
  String get templateWelcome => _templateWelcome;
  String get templateGeneralNote => _templateGeneralNote;
  bool get examMode => _examMode;
  bool get isExamModeActive => _examMode;
  // Unified 3-way theme key
  String get appThemeMode {
    if (_examMode) return 'exam';
    if (_darkMode) return 'dark';
    return 'light';
  }
  // examMode implies dark, so effective dark = darkMode OR examMode
  bool get effectiveDarkMode => _darkMode || _examMode;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _teacherName = _prefs.getString(AppConstants.prefTeacherName) ?? 'المعلم';
    _teacherPhone = _prefs.getString(AppConstants.prefTeacherPhone) ?? '';

    // Load mySubjects from prefMySubjects or legacy prefTeacherSpecialties
    final storedSubjects = _prefs.getStringList(AppConstants.prefMySubjects) ??
        _prefs.getStringList(AppConstants.prefTeacherSpecialties);
    if (storedSubjects != null && storedSubjects.isNotEmpty) {
      _mySubjects = List.from(storedSubjects);
    } else {
      _mySubjects = List.from(AppConstants.defaultSubjects);
    }

    _darkMode = _prefs.getBool(AppConstants.prefDarkMode) ?? false;
    _notifSession = _prefs.getBool(AppConstants.prefNotifSession) ?? true;
    _notifAbsence = _prefs.getBool(AppConstants.prefNotifAbsence) ?? true;
    _notifPayment = _prefs.getBool(AppConstants.prefNotifPayment) ?? true;
    _notifExam = _prefs.getBool(AppConstants.prefNotifExam) ?? true;
    _paymentReminderDay = _prefs.getInt('payment_reminder_day') ?? 5;
    _sessionReminderMinutes = _prefs.getInt('session_reminder_minutes') ?? 10;
    _onboardingDone = _prefs.getBool(AppConstants.prefOnboardingDone) ?? false;
    _attendanceAutoOpened = _prefs.getBool(AppConstants.prefAttendanceAutoOpened) ?? false;
    _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
    _developerMode = _prefs.getBool('developer_mode') ?? false;
    _defaultContactMethod = _prefs.getString('default_contact_method') ?? 'ask';
    _defaultPaymentMode = _prefs.getString('default_payment_mode') ?? 'monthly';
    _folderCardStyle = _prefs.getBool('folder_card_style') ?? false;
    _studentCardStyle = _prefs.getString('student_card_style') ?? (_folderCardStyle ? 'folder' : 'modern');
    _groupCardStyle = _prefs.getString('group_card_style') ?? 'classic';
    _attendanceMode = _prefs.getString('attendance_mode') ?? 'list';
    _dateFormatType = _prefs.getString('date_format_type') ?? 'both';
    _biometricEnabled = _prefs.getBool('biometric_enabled') ?? false;
    _notifSound = _prefs.getString(AppConstants.prefNotifSound) ?? 'bell';
    _splashTheme = _prefs.getString('splash_theme') ?? 'emerald';
    _boldFont = _prefs.getBool('pref_bold_font') ?? false;
    _homeDesignStyle = _prefs.getString('home_design_style') ?? 'modern';
    _examMode = _prefs.getBool('exam_mode') ?? false;
    _fontScale = _prefs.getDouble('font_scale') ?? 1.0;

    _templateAbsence = _prefs.getString(AppConstants.prefTemplateAbsence) ?? 'السلام عليكم، نود إبلاغكم بأن الطالب {student} غاب النهاردة عن حصة {group} بتاريخ {date}.';
    _templatePayment = _prefs.getString(AppConstants.prefTemplatePayment) ?? 'السلام عليكم، نود تذكيركم بتسديد اشتراك شهر {month} للطالب {student}.';
    _templateExam = _prefs.getString(AppConstants.prefTemplateExam) ?? 'السلام عليكم، جاب {student} {mark} من {total} في اختبار {exam}.';
    _templateCancelSession = _prefs.getString('template_cancel_session') ?? 'السلام عليكم ورحمة الله، نود إبلاغكم بإلغاء حصة {group} بتاريخ {date}. {compensation}';
    _templateWelcome = _prefs.getString('template_welcome') ?? 'أهلاً بك يا {student} في مجموعة {group} مع الأستاذ {teacher}. نتمنى لك تفوقاً دائماً 🌟';
    _templateGeneralNote = _prefs.getString('template_general_note') ?? 'السلام عليكم، رسالة هامة بخصوص الطالب {student}: {note}';

    _initialized = true;
    notifyListeners();
  }

  String _homeDesignStyle = 'modern';
  String get homeDesignStyle => _homeDesignStyle;

  Future<void> setHomeDesignStyle(String style) async {
    _homeDesignStyle = style;
    await _prefs.setString('home_design_style', style);
    notifyListeners();
  }

  Future<void> setFontScale(double val) async {
    _fontScale = val;
    await _prefs.setDouble('font_scale', val);
    notifyListeners();
  }

  Future<void> setDarkMode(bool val) async {
    _darkMode = val;
    if (val) _examMode = false;
    await _prefs.setBool(AppConstants.prefDarkMode, val);
    await _prefs.setBool('exam_mode', _examMode);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    await setDarkMode(!_darkMode);
  }

  Future<void> setExamMode(bool val) async {
    _examMode = val;
    if (val) _darkMode = false;
    await _prefs.setBool('exam_mode', val);
    await _prefs.setBool(AppConstants.prefDarkMode, _darkMode);
    notifyListeners();
  }

  Future<void> toggleExamMode() async {
    await setExamMode(!_examMode);
  }

  Future<void> setAppThemeMode(String mode) async {
    if (mode == 'exam') {
      _examMode = true;
      _darkMode = false;
    } else if (mode == 'dark') {
      _examMode = false;
      _darkMode = true;
    } else {
      _examMode = false;
      _darkMode = false;
    }
    await _prefs.setBool('exam_mode', _examMode);
    await _prefs.setBool(AppConstants.prefDarkMode, _darkMode);
    notifyListeners();
  }

  bool _boldFont = false;
  bool get boldFont => _boldFont;

  Future<void> setBoldFont(bool val) async {
    _boldFont = val;
    await _prefs.setBool('pref_bold_font', val);
    notifyListeners();
  }

  String _splashTheme = 'emerald';
  String get splashTheme => _splashTheme;

  Future<void> setSplashTheme(String theme) async {
    _splashTheme = theme;
    await _prefs.setString('splash_theme', theme);
    notifyListeners();
  }

  Future<void> setStudentCardStyle(String style) async {
    _studentCardStyle = style;
    _folderCardStyle = (style == 'folder');
    await _prefs.setString('student_card_style', style);
    await _prefs.setBool('folder_card_style', _folderCardStyle);
    notifyListeners();
  }

  Future<void> setGroupCardStyle(String style) async {
    _groupCardStyle = style;
    await _prefs.setString('group_card_style', style);
    notifyListeners();
  }

  Future<void> setAttendanceMode(String mode) async {
    _attendanceMode = mode;
    await _prefs.setString('attendance_mode', mode);
    notifyListeners();
  }

  Future<void> setAttendanceAutoOpened(bool value) async {
    _attendanceAutoOpened = value;
    await _prefs.setBool(AppConstants.prefAttendanceAutoOpened, value);
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    await _prefs.setBool('biometric_enabled', value);
    notifyListeners();
  }

  Future<void> setDateFormatType(String value) async {
    _dateFormatType = value;
    await _prefs.setString('date_format_type', value);
    notifyListeners();
  }

  Future<void> setFolderCardStyle(bool value) async {
    _folderCardStyle = value;
    _studentCardStyle = value ? 'folder' : 'modern';
    _groupCardStyle = value ? 'folder' : 'classic';
    await _prefs.setBool('folder_card_style', value);
    await _prefs.setString('student_card_style', _studentCardStyle);
    await _prefs.setString('group_card_style', _groupCardStyle);
    notifyListeners();
  }

  Future<void> setTeacherName(String name) async {
    _teacherName = name;
    await _prefs.setString(AppConstants.prefTeacherName, name);
    notifyListeners();
  }

  Future<void> setTeacherPhone(String phone) async {
    _teacherPhone = phone;
    await _prefs.setString(AppConstants.prefTeacherPhone, phone);
    notifyListeners();
  }

  Future<void> setMySubjects(List<String> subjects) async {
    _mySubjects = List.from(subjects);
    await _prefs.setStringList(AppConstants.prefMySubjects, subjects);
    await _prefs.setStringList(AppConstants.prefTeacherSpecialties, subjects);
    notifyListeners();
  }

  Future<void> setTeacherSpecialties(List<String> specialties) async {
    await setMySubjects(specialties);
  }

  Future<void> addSubject(String subject) async {
    final trimmed = subject.trim();
    if (trimmed.isEmpty || _mySubjects.contains(trimmed)) return;
    _mySubjects.add(trimmed);
    await _prefs.setStringList(AppConstants.prefMySubjects, _mySubjects);
    await _prefs.setStringList(AppConstants.prefTeacherSpecialties, _mySubjects);
    notifyListeners();
  }



  Future<void> setNotifSession(bool value) async {
    _notifSession = value;
    await _prefs.setBool(AppConstants.prefNotifSession, value);
    notifyListeners();
  }

  Future<void> setNotifAbsence(bool value) async {
    _notifAbsence = value;
    await _prefs.setBool(AppConstants.prefNotifAbsence, value);
    notifyListeners();
  }

  Future<void> setNotifPayment(bool value) async {
    _notifPayment = value;
    await _prefs.setBool(AppConstants.prefNotifPayment, value);
    notifyListeners();
  }

  Future<void> setNotifExam(bool value) async {
    _notifExam = value;
    await _prefs.setBool(AppConstants.prefNotifExam, value);
    notifyListeners();
  }

  Future<void> setPaymentReminderDay(int day) async {
    _paymentReminderDay = day;
    await _prefs.setInt('payment_reminder_day', day);
    notifyListeners();
  }

  Future<void> setSessionReminderMinutes(int minutes) async {
    _sessionReminderMinutes = minutes;
    await _prefs.setInt('session_reminder_minutes', minutes);
    notifyListeners();
  }

  Future<void> setNotifSound(String sound) async {
    _notifSound = sound;
    await _prefs.setString(AppConstants.prefNotifSound, sound);
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    await _prefs.setBool('notifications_enabled', _notificationsEnabled);
    notifyListeners();
  }

  void toggleDeveloperMode() {
    _developerMode = !_developerMode;
    _prefs.setBool('developer_mode', _developerMode);
    notifyListeners();
  }

  void recordError(String error, StackTrace? stack) {
    _lastError = '$error\n\n$stack';
    notifyListeners();
  }

  Future<void> setDefaultContactMethod(String method) async {
    _defaultContactMethod = method;
    await _prefs.setString('default_contact_method', method);
    notifyListeners();
  }

  Future<void> setDefaultPaymentMode(String mode) async {
    _defaultPaymentMode = mode;
    await _prefs.setString('default_payment_mode', mode);
    notifyListeners();
  }

  Future<void> setTemplateAbsence(String value) async {
    _templateAbsence = value;
    await _prefs.setString(AppConstants.prefTemplateAbsence, value);
    notifyListeners();
  }

  Future<void> setTemplatePayment(String value) async {
    _templatePayment = value;
    await _prefs.setString(AppConstants.prefTemplatePayment, value);
    notifyListeners();
  }

  Future<void> setTemplateExam(String value) async {
    _templateExam = value;
    await _prefs.setString(AppConstants.prefTemplateExam, value);
    notifyListeners();
  }

  Future<void> setTemplateCancelSession(String value) async {
    _templateCancelSession = value;
    await _prefs.setString('template_cancel_session', value);
    notifyListeners();
  }

  Future<void> setTemplateWelcome(String value) async {
    _templateWelcome = value;
    await _prefs.setString('template_welcome', value);
    notifyListeners();
  }

  Future<void> setTemplateGeneralNote(String value) async {
    _templateGeneralNote = value;
    await _prefs.setString('template_general_note', value);
    notifyListeners();
  }

  Future<void> seedDemoData() async {
    final db = DatabaseHelper();
    // Add 2 demo groups
    final g1 = GroupModel(
      id: 'demo-g1',
      name: 'مجموعة العباقرة (فيزياء)',
      type: GroupType.center,
      subject: 'الفيزياء',
      days: const [GroupDay(day: 'السبت', time: '17:00'), GroupDay(day: 'الثلاثاء', time: '17:00')],
      monthlyPrice: 200,
      whatsappLink: 'https://chat.whatsapp.com/demo1',
      status: GroupStatus.active,
      createdAt: DateTime.now(),
    );
    final g2 = GroupModel(
      id: 'demo-g2',
      name: 'أوائل الثانوية (رياضيات)',
      type: GroupType.online,
      subject: 'الرياضيات',
      days: const [GroupDay(day: 'الأحد', time: '19:00'), GroupDay(day: 'الأربعاء', time: '19:00')],
      monthlyPrice: 180,
      whatsappLink: 'https://chat.whatsapp.com/demo2',
      status: GroupStatus.active,
      createdAt: DateTime.now(),
    );
    await db.insert(AppConstants.tableGroups, g1.toMap());
    await db.insert(AppConstants.tableGroups, g2.toMap());

    // Add 6 demo students
    final names = ['أحمد محمد إبراهيم', 'سارة محمود علي', 'يوسف كريم طارق', 'مريم خالد حسن', 'عمر عبد الرحمن', 'نور الدين مصطفى'];
    for (int i = 0; i < names.length; i++) {
      final s = StudentModel(
        id: 'demo-s$i',
        name: names[i],
        phone: '010${12345670 + i}',
        parentPhone: '011${98765430 + i}',
        level: 7 + (i % 3),
        groupId: i < 3 ? 'demo-g1' : 'demo-g2',
        points: 40 + (i * 15),
        discountType: i == 1 ? 'exempt' : (i == 2 ? 'fixed' : 'none'),
        discountAmount: i == 2 ? 50 : 0,
        discountReason: i == 1 ? 'إعفاء كامل (حالة خاصة)' : (i == 2 ? 'خصم أخوة' : ''),
        createdAt: DateTime.now(),
      );
      await db.insert(AppConstants.tableStudents, s.toMap());
    }
  }

  Future<void> completeOnboarding({
    required String name,
    String phone = '',
    required List<String> subjects,
  }) async {
    _teacherName = name;
    _teacherPhone = phone;
    _mySubjects = List.from(subjects);
    _onboardingDone = true;
    await _prefs.setString(AppConstants.prefTeacherName, name);
    await _prefs.setString(AppConstants.prefTeacherPhone, phone);
    await _prefs.setStringList(AppConstants.prefMySubjects, subjects);
    await _prefs.setStringList(AppConstants.prefTeacherSpecialties, subjects);
    await _prefs.setBool(AppConstants.prefOnboardingDone, true);
    notifyListeners();
  }

  Future<void> markAttendanceAutoOpened() async {
    _attendanceAutoOpened = true;
    await _prefs.setBool(AppConstants.prefAttendanceAutoOpened, true);
    notifyListeners();
  }
}
