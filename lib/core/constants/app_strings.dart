class AppStrings {
  // App
  static const String appName = 'مُساعِد المُعلِّم';
  static const String appSubtitle = 'إدارة الطلاب بسهولة';

  // Navigation
  static const String navHome = 'الرئيسية';
  static const String navGroups = 'المجموعات';
  static const String navStudents = 'الطلاب';
  static const String navSchedule = 'الجدول';
  static const String navFinance = 'المالية';

  // Home
  static const String greeting = 'أ.';
  static const String totalStudents = 'إجمالي الطلاب';
  static const String totalGroups = 'إجمالي المجموعات';
  static const String absentToday = 'غائبون اليوم';
  static const String nextSession = 'الحصة القادمة';
  static const String todayGroups = 'مجموعات اليوم';
  static const String noSessionsToday = 'لا توجد حصص اليوم';
  static const String minutesRemaining = 'دقيقة متبقية';
  static const String sessionStarted = 'الحصة بدأت';
  static const String recordAttendance = 'تسجيل حضور';

  // Groups
  static const String groups = 'المجموعات';
  static const String addGroup = 'إضافة مجموعة';
  static const String editGroup = 'تعديل المجموعة';
  static const String deleteGroup = 'حذف المجموعة';
  static const String groupName = 'اسم المجموعة';
  static const String groupType = 'نوع المجموعة';
  static const String groupSubject = 'المادة';
  static const String groupDays = 'الأيام والأوقات';
  static const String monthlyPrice = 'السعر الشهري';
  static const String addDay = 'إضافة يوم';
  static const String groupStatus = 'حالة المجموعة';
  static const String confirmDeleteGroup = 'هل أنت متأكد من حذف المجموعة؟';
  static const String groupHasStudents = 'المجموعة تحتوي على طلاب، نقلهم أولاً؟';
  static const String noGroups = 'لا توجد مجموعات بعد';
  static const String addFirstGroup = 'أضف مجموعتك الأولى';
  static const String studentCount = 'طالب';
  static const String topStudents = 'متفوقين';
  static const String midStudents = 'متوسطين';
  static const String weakStudents = 'ضعاف';
  static const String allFilter = 'الكل';

  // Group Types
  static const String typeCenter = 'سنتر';
  static const String typeOnline = 'أونلاين';
  static const String typeOther = 'أخرى';

  // Group Subjects
  static const String subjectGem = 'Gem';
  static const String subjectMoaaser = 'المعاصر';
  static const String subjectOther = 'أخرى';

  // Group Status
  static const String statusActive = 'نشطة';
  static const String statusPaused = 'متوقفة';
  static const String statusEnded = 'منتهية';

  // Days
  static const String saturday = 'السبت';
  static const String sunday = 'الأحد';
  static const String monday = 'الاثنين';
  static const String tuesday = 'الثلاثاء';
  static const String wednesday = 'الأربعاء';
  static const String thursday = 'الخميس';
  static const String friday = 'الجمعة';
  static const List<String> days = [saturday, sunday, monday, tuesday, wednesday, thursday, friday];
  static const List<String> arabicDays = days;

  // Students
  static const String students = 'الطلاب';
  static const String addStudent = 'إضافة طالب';
  static const String editStudent = 'تعديل الطالب';
  static const String deleteStudent = 'حذف الطالب';
  static const String studentName = 'اسم الطالب';
  static const String studentPhone = 'رقم الهاتف';
  static const String parentPhone = 'رقم ولي الأمر';
  static const String studentLevel = 'مستوى الطالب';
  static const String studentGroup = 'المجموعة';
  static const String studentNotes = 'ملاحظات';
  static const String noStudents = 'لا يوجد طلاب بعد';
  static const String addFirstStudent = 'أضف طالبك الأول';
  static const String searchStudents = 'بحث بالاسم أو الهاتف...';
  static const String noGroupFirst = 'يجب إضافة مجموعة أولاً';
  static const String confirmDeleteStudent = 'هل أنت متأكد من حذف هذا الطالب؟';
  static const String callStudent = 'اتصال بالطالب';
  static const String callParent = 'اتصال بولي الأمر';
  static const String whatsappStudent = 'واتساب الطالب';
  static const String whatsappParent = 'واتساب ولي الأمر';
  static const String levelBad = 'سيء';
  static const String levelGood = 'جيد';

  // Student Status
  static const String studentActive = 'نشط';
  static const String studentDeleted = 'محذوف';

  // Attendance
  static const String attendance = 'الحضور';
  static const String saveAttendance = 'حفظ الحضور';
  static const String attendanceSaved = '✅ تم حفظ الحضور';
  static const String present = 'حاضر';
  static const String absent = 'غائب';
  static const String homeworkDone = 'عمل الواجب';
  static const String homeworkNotDone = 'لم يعمل الواجب';
  static const String quickNote = 'ملاحظة سريعة';
  static const String attendanceHistory = 'سجل الحضور';
  static const String noAttendanceRecords = 'لا يوجد سجل حضور';
  static const String futureDate = 'لا يمكن تسجيل حضور لتاريخ مستقبلي';

  // Exams
  static const String exams = 'الاختبارات';
  static const String addExam = 'إضافة اختبار';
  static const String editExam = 'تعديل الاختبار';
  static const String examName = 'اسم الاختبار';
  static const String totalMarks = 'الدرجة الكلية';
  static const String examDate = 'تاريخ الاختبار';
  static const String studentMarks = 'درجة الطالب';
  static const String enterMarks = 'إدخال الدرجات';
  static const String highest = 'الأعلى';
  static const String lowest = 'الأدنى';
  static const String average = 'المتوسط';
  static const String passRate = 'نسبة النجاح';
  static const String sendWhatsapp = 'إرسال واتساب';
  static const String noExams = 'لا يوجد اختبارات بعد';
  static const String examResultMessage = 'جاب {name} {marks} من {total} في {exam}';

  // Finance
  static const String finance = 'المالية';
  static const String expectedIncome = 'الإيراد المتوقع';
  static const String collectedIncome = 'المحصّل';
  static const String remaining = 'المتبقي';
  static const String collectionRate = 'نسبة التحصيل';
  static const String paymentStatus = 'حالة الدفع';
  static const String paid = 'دفع';
  static const String partialPayment = 'جزئي';
  static const String notPaid = 'لم يدفع';
  static const String partialAmount = 'المبلغ المدفوع';
  static const String month = 'شهر';
  static const String futureMonth = 'لا يمكن تسجيل دفع لشهر مستقبلي';
  static const String currency = 'ج.م';

  // Schedule
  static const String schedule = 'الجدول';
  static const String today = 'اليوم';
  static const String noScheduledSessions = '☕ لا توجد حصص مجدولة في هذا اليوم';
  static const String allDays = 'الكل';

  // Reports
  static const String reports = 'التقارير';
  static const String generateReport = 'إنشاء تقرير';
  static const String exportPdf = 'تصدير PDF';
  static const String shareReport = 'مشاركة التقرير';
  static const String attendanceTable = 'جدول الحضور';
  static const String examResults = 'نتائج الاختبارات';
  static const String reportGenerated = '✅ تم إنشاء التقرير';

  // Notifications
  static const String notifications = 'التنبيهات';
  static const String sessionReminder = 'تذكير الحصة';
  static const String absenceSummary = 'ملخص الغياب';
  static const String paymentReminder = 'تذكير الدفع';
  static const String sessionReminderMsg = 'مجموعة {group} بعد 10 دقائق - 📍 {location}';
  static const String absenceSummaryMsg = 'ملخص الغياب: {count} طلاب غائبين اليوم';
  static const String paymentReminderMsg = 'تذكير: {count} طلاب متأخرين في دفع الاشتراك';

  // Points
  static const String points = 'النقاط';
  static const String leaderboard = 'المتصدرون';
  static const String pointsLabel = 'نقطة';

  // Settings
  static const String settings = 'الإعدادات';
  static const String teacherName = 'اسم المعلم';
  static const String darkMode = 'الوضع الداكن';
  static const String notificationSettings = 'إعدادات التنبيهات';
  static const String backup = 'النسخ الاحتياطي';
  static const String restore = 'الاستعادة';
  static const String exportData = 'تصدير البيانات';
  static const String aboutApp = 'عن التطبيق';
  static const String backupSuccess = '✅ تم حفظ النسخة الاحتياطية';
  static const String restoreSuccess = '✅ تم استعادة البيانات';
  static const String confirmRestore = 'هل أنت متأكد؟ سيتم استبدال جميع البيانات الحالية.';
  static const String version = 'الإصدار 1.0.0';

  // Onboarding
  static const String welcome = 'أهلاً بك!';
  static const String onboardingTitle = 'مُساعِد المُعلِّم';
  static const String onboardingSubtitle = 'نظام إدارة متكامل للمعلمين';
  static const String enterYourName = 'أدخل اسمك';
  static const String teacherNameHint = 'مثال: أحمد محمد';
  static const String getStarted = 'ابدأ الآن';

  // Common
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String add = 'إضافة';
  static const String confirm = 'تأكيد';
  static const String yes = 'نعم';
  static const String no = 'لا';
  static const String close = 'إغلاق';
  static const String loading = 'جار التحميل...';
  static const String error = 'خطأ';
  static const String success = 'تم بنجاح';
  static const String requiredField = 'هذا الحقل مطلوب';
  static const String invalidPhone = 'رقم الهاتف غير صحيح';
  static const String pounds = 'جنيه';
  static const String copyMessage = 'نسخ الرسالة';
  static const String messageCopied = 'تم نسخ الرسالة';
  static const String at = 'الساعة';
  static const String from = 'من';
  static const String noData = 'لا توجد بيانات';
}
