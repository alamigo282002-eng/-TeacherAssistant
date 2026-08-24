class AppConstants {
  // DB
  static const String dbName = 'teacher_assistant.db';
  static const int dbVersion = 1;

  // Tables
  static const String tableGroups = 'groups';
  static const String tableStudents = 'students';
  static const String tableAttendance = 'attendance';
  static const String tableExams = 'exams';
  static const String tableExamResults = 'exam_results';
  static const String tablePayments = 'payments';
  static const String tableNotes = 'notes';
  static const String tableAppLock = 'app_lock';
  static const String tableAutoBackup = 'auto_backup';
  static const String tableActivityLogs = 'activity_logs';
  static const String tableNews = 'news_items';
  static const String tableAnnouncements = 'announcements';

  // Record Statuses
  static const String statusActive = 'نشط';
  static const String statusDeleted = 'محذوف';
  static const String statusSuspended = 'موقوف';

  // SharedPreferences keys
  static const String prefTeacherName = 'teacher_name';
  static const String prefTeacherPhone = 'teacher_phone';
  static const String prefMySubjects = 'my_subjects';
  static const String prefTeacherSpecialties = 'teacher_specialties'; // legacy alias
  static const String prefDarkMode = 'dark_mode';
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefAttendanceAutoOpened = 'attendance_auto_opened';
  static const String prefNotifSession = 'notif_session';
  static const String prefNotifAbsence = 'notif_absence';
  static const String prefNotifPayment = 'notif_payment';
  static const String prefNotifExam = 'notif_exam';
  static const String prefNotifSound = 'notif_sound';

  // Templates
  static const String prefTemplateAbsence = 'template_absence';
  static const String prefTemplatePayment = 'template_payment';
  static const String prefTemplateExam = 'template_exam';

  // WhatsApp Community link
  static const String whatsappCommunityUrl = 'https://chat.whatsapp.com/xxxxxxxxxxxxx';

  // Default Teacher Subjects per §3
  static const List<String> defaultSubjects = [
    'اللغة العربية',
    'الرياضيات',
    'العلوم',
    'اللغة الإنجليزية',
    'الفيزياء',
    'الكيمياء',
    'الأحياء',
    'الدراسات الاجتماعية',
    'اللغة الفرنسية',
  ];
  static const List<String> defaultSpecialties = defaultSubjects;

  // Points
  static const int pointsForAttendance = 1;
  static const int pointsForHomework = 1;
  static const int pointsForExamPerfect = 5;
  static const int pointsForExamGood = 3;
  static const int pointsForExamPass = 1;

  // Level thresholds (for group stats from exams)
  static const double topThreshold = 0.75;    // >= 75% = متفوق
  static const double midThreshold = 0.50;    // >= 50% = متوسط
                                               // <  50% = ضعيف

  // Attendance lock hours
  static const int attendanceLockHours = 24;

  // Payment reminder day
  static const int paymentReminderDay = 5;

  // Session reminder minutes before
  static const int sessionReminderMinutes = 10;

  // WhatsApp URL prefix
  static const String whatsappUrl = 'https://wa.me/';
  static const String whatsappTextPrefix = '?text=';

  // Notification channels
  static const String notifChannelIdSession = 'session_reminder';
  static const String notifChannelNameSession = 'تذكير الحصة (قبل البدء بـ 15 دقيقة)';
  static const String notifChannelIdGroupEnd = 'group_end_reminder';
  static const String notifChannelNameGroupEnd = 'تنبيه انتهاء الحصة لرصد الغياب';
  static const String notifChannelIdNotes = 'notes_reminder';
  static const String notifChannelNameNotes = 'تذكير الملاحظات والمهام';
  static const String notifChannelIdDaily = 'daily_summary';
  static const String notifChannelNameDaily = 'الملخص اليومي';
  static const String notifChannelIdAbsence = 'absence_summary';
  static const String notifChannelNameAbsence = 'ملخص الغياب';
  static const String notifChannelIdPayment = 'payment_reminder';
  static const String notifChannelNamePayment = 'تذكير الدفع والاشتراكات';

  // Exam pass threshold
  static const double passThreshold = 0.50;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
}

// Enums
enum LockType { pin, biometric, both }
enum BackupFrequency { weekly, monthly }
enum ScheduleViewType { timeline, tabs }
enum ThemeModeApp { light, dark, system }
enum Gender { male, female }

enum GroupType { center, online, other }
extension GroupTypeExt on GroupType {
  String get label {
    switch (this) {
      case GroupType.center: return 'سنتر';
      case GroupType.online: return 'أونلاين';
      case GroupType.other: return 'أخرى';
    }
  }
  static GroupType fromLabel(String label) {
    switch (label) {
      case 'سنتر': return GroupType.center;
      case 'أونلاين': return GroupType.online;
      default: return GroupType.other;
    }
  }
}

enum GroupStatus { active, paused, ended }
extension GroupStatusExt on GroupStatus {
  String get label {
    switch (this) {
      case GroupStatus.active: return 'نشطة';
      case GroupStatus.paused: return 'متوقفة';
      case GroupStatus.ended: return 'منتهية';
    }
  }
  static GroupStatus fromLabel(String label) {
    switch (label) {
      case 'نشطة': return GroupStatus.active;
      case 'متوقفة': return GroupStatus.paused;
      case 'منتهية': return GroupStatus.ended;
      default: return GroupStatus.paused;
    }
  }
}

enum StudentStatus { active, deleted }
extension StudentStatusExt on StudentStatus {
  String get label => this == StudentStatus.active ? 'نشط' : 'محذوف';
  static StudentStatus fromLabel(String label) =>
      label == 'نشط' ? StudentStatus.active : StudentStatus.deleted;
}

enum AttendanceStatus {
  present('حاضر'),
  absent('غائب'),
  excused('تخطي'),
  cancelled('ملغاة');

  final String label;
  const AttendanceStatus(this.label);

  static AttendanceStatus fromLabel(String label) {
    switch (label) {
      case 'حاضر': return AttendanceStatus.present;
      case 'تخطي':
      case 'معذور': return AttendanceStatus.excused;
      case 'ملغاة': return AttendanceStatus.cancelled;
      default: return AttendanceStatus.absent;
    }
  }
}

extension AttendanceStatusExt on AttendanceStatus {
  static AttendanceStatus fromLabel(String label) => AttendanceStatus.fromLabel(label);
}

enum PaymentType {
  full('كامل'),
  partial('جزئي'),
  unpaid('لم يدفع');

  final String label;
  const PaymentType(this.label);

  static PaymentType fromLabel(String label) {
    switch (label) {
      case 'كامل': return PaymentType.full;
      case 'جزئي': return PaymentType.partial;
      default: return PaymentType.unpaid;
    }
  }
}

extension PaymentTypeExt on PaymentType {
  static PaymentType fromLabel(String label) => PaymentType.fromLabel(label);
}
