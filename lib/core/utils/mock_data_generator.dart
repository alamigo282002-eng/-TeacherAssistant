import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/student_model.dart';
import 'arabic_numbers.dart';
import 'date_helper.dart';

/// محرك توليد البيانات التجريبية الضخمة والواقعية لاختبار التطبيق
class MockDataGenerator {
  static final _uuid = const Uuid();
  static final _rnd = Random();

  static const List<String> _maleFirstNames = [
    'أحمد', 'محمد', 'عمر', 'يوسف', 'زياد', 'علي', 'حمزة', 'طارق', 'سيف', 'خالد',
    'إبراهيم', 'حسن', 'مصطفى', 'كريم', 'آسر', 'أنس', 'بلال', 'مالك', 'يحيى', 'مروان',
    'مازن', 'سامر', 'هيثم', 'أيمن', 'وليد', 'إسلام', 'رامي', 'شادي', 'حازم', 'عمار',
    'فارس', 'سليم', 'حاتم', 'صالح', 'أشرف', 'باسم', 'تامر', 'سامح', 'معاذ', 'ياسين'
  ];

  static const List<String> _femaleFirstNames = [
    'سلمى', 'مريم', 'سارة', 'فاطمة', 'خديجة', 'ياسمين', 'ملك', 'جنى', 'هنا', 'فريدة',
    'ريم', 'ليلى', 'حبيبة', 'ندى', 'جودي', 'حنين', 'رضوى', 'آية', 'أسماء', 'شهد',
    'بسملة', 'منة', 'شروق', 'هاجر', 'دعاء', 'إيمان', 'نور', 'دانة', 'تسنيم', 'تقى',
    'روان', 'رودينا', 'ريتاج', 'كنزي', 'ريناد', 'ماهيتاب', 'نوران', 'دنيا', 'ميار', 'رغد'
  ];

  static const List<String> _familyNames = [
    'الشريف', 'الصياد', 'العوضي', 'النجار', 'فاروق', 'بدران', 'القاضي', 'السعيد', 'رضوان',
    'التهامي', 'الألفي', 'عثمان', 'حسنين', 'عبد الله', 'عبد الرحمن', 'الهواري', 'خليل',
    'جاد', 'شحاتة', 'زكي', 'علام', 'درويش', 'غنيم', 'هيكل', 'الديب', 'منصور', 'فؤاد',
    'غانم', 'يونس', 'زهران', 'الباز', 'شومان', 'عفيفي', 'بركات', 'السيد', 'البحيري'
  ];

  static const List<String> _subjects = [
    'رياضيات', 'لغة عربية', 'فيزياء', 'كيمياء', 'لغة إنجليزية', 'أحياء',
    'لغة فرنسية', 'دراسات اجتماعية', 'تاريخ', 'جغرافيا', 'فلسفة ومنطق', 'علوم متكاملة'
  ];

  static const List<String> _stages = [
    'الصف الأول الإعدادي', 'الصف الثاني الإعدادي', 'الصف الثالث الإعدادي',
    'الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'
  ];

  static const List<String> _centerNames = [
    'سنتر الأوائل', 'سنتر النخبة', 'سنتر التفوق', 'سنتر الأمل', 'سنتر الفرسان',
    'سنتر إكسيلانس', 'قاعة المنار', 'سنتر العباقرة', 'سنتر المستقبل', 'سنتر القمة'
  ];

  static const List<String> _arabicDays = [
    'السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'
  ];

  static String _randomPhone() {
    final prefixes = ['010', '011', '012', '015'];
    final prefix = prefixes[_rnd.nextInt(prefixes.length)];
    final number = (_rnd.nextInt(90000000) + 10000000).toString();
    return '$prefix$number';
  }

  static String _randomStudentName() {
    final isMale = _rnd.nextBool();
    final first = isMale
        ? _maleFirstNames[_rnd.nextInt(_maleFirstNames.length)]
        : _femaleFirstNames[_rnd.nextInt(_femaleFirstNames.length)];
    final middle = _maleFirstNames[_rnd.nextInt(_maleFirstNames.length)];
    final family = _familyNames[_rnd.nextInt(_familyNames.length)];
    return '$first $middle $family';
  }

  /// 1. توليد مجموعات تجريبية
  static Future<List<GroupModel>> generateMockGroups(int count) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final List<GroupModel> createdGroups = [];

    for (int i = 0; i < count; i++) {
      final subject = _subjects[_rnd.nextInt(_subjects.length)];
      final stage = _stages[_rnd.nextInt(_stages.length)];
      final isOnline = _rnd.nextDouble() < 0.25;
      final center = _centerNames[_rnd.nextInt(_centerNames.length)];
      final groupName = '$subject - $stage (${isOnline ? "أونلاين" : center} ${i + 1})';

      // Pick 2 random days
      final day1 = _arabicDays[_rnd.nextInt(_arabicDays.length)];
      var day2 = _arabicDays[_rnd.nextInt(_arabicDays.length)];
      while (day2 == day1) {
        day2 = _arabicDays[_rnd.nextInt(_arabicDays.length)];
      }

      final hours = ['03:00 م', '04:30 م', '06:00 م', '07:30 م', '09:00 ص', '11:00 ص'];
      final time1 = hours[_rnd.nextInt(hours.length)];
      final time2 = hours[_rnd.nextInt(hours.length)];

      final group = GroupModel(
        id: _uuid.v4(),
        name: groupName,
        subject: subject,
        days: [
          GroupDay(day: day1, time: time1),
          GroupDay(day: day2, time: time2),
        ],
        monthlyPrice: (150 + _rnd.nextInt(15) * 10).toDouble(), // 150 - 300 EGP
        sessionPrice: (40 + _rnd.nextInt(6) * 5).toDouble(), // 40 - 70 EGP
        type: isOnline ? GroupType.online : GroupType.center,
        status: GroupStatus.active,
        whatsappLink: isOnline ? 'https://chat.whatsapp.com/mockGroup${_rnd.nextInt(9999)}' : '',
        onlinePlatform: isOnline ? 'Zoom' : null,
        onlineMeetingUrl: isOnline ? 'https://zoom.us/j/mock${_rnd.nextInt(999999)}' : null,
        createdAt: DateTime.now().subtract(Duration(days: _rnd.nextInt(60))),
      );

      await db.insert('groups', group.toMap());
      createdGroups.add(group);
    }

    return createdGroups;
  }

  /// 2. توليد طلاب تجريبيين مع ربطهم بالمجموعات
  static Future<List<StudentModel>> generateMockStudents({
    required int count,
    List<String>? targetGroupIds,
  }) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    List<String> groupIds = targetGroupIds ?? [];
    if (groupIds.isEmpty) {
      final groups = await db.query('groups');
      groupIds = groups.map((g) => g['id'] as String).toList();
    }

    if (groupIds.isEmpty) {
      // Create at least 2 groups if none exist
      final created = await generateMockGroups(2);
      groupIds = created.map((g) => g.id).toList();
    }

    final List<StudentModel> createdStudents = [];

    for (int i = 0; i < count; i++) {
      final assignedGroupId = groupIds[_rnd.nextInt(groupIds.length)];
      final studentName = _randomStudentName();
      final hasDiscount = _rnd.nextDouble() < 0.15;
      final discountAmount = hasDiscount ? (20 + _rnd.nextInt(4) * 10).toDouble() : 0.0;
      final discountType = hasDiscount ? 'fixed' : 'none';
      final discountReason = hasDiscount ? 'خصم تفوق / أشقاء' : '';

      final student = StudentModel(
        id: _uuid.v4(),
        name: studentName,
        phone: _randomPhone(),
        parentPhone: _randomPhone(),
        level: _rnd.nextInt(5) + 1,
        groupId: assignedGroupId,
        specialNote: _rnd.nextDouble() < 0.2 ? 'يصل متأخراً 10 دقائق بسبب المواصلات' : '',
        points: _rnd.nextInt(45),
        status: StudentStatus.active,
        discountAmount: discountAmount,
        discountType: discountType,
        discountReason: discountReason,
        paymentMode: _rnd.nextDouble() < 0.8 ? 'monthly' : 'per_session',
        createdAt: DateTime.now().subtract(Duration(days: _rnd.nextInt(90))),
      );

      await db.insert('students', student.toMap());
      createdStudents.add(student);
    }

    return createdStudents;
  }

  /// 3. توليد سجلات حضور وغياب وتسميع لعدة أيام سابقة
  static Future<int> generateMockAttendanceHistory({int sessionsCount = 8}) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final groups = await db.query('groups');
    if (groups.isEmpty) return 0;

    int totalRecords = 0;
    final now = DateTime.now();

    for (final g in groups) {
      final gId = g['id'] as String;
      final students = await db.query('students', where: 'group_id = ?', whereArgs: [gId]);
      if (students.isEmpty) continue;

      for (int s = 0; s < sessionsCount; s++) {
        final sessionDate = now.subtract(Duration(days: (s * 3) + 1));

        for (final st in students) {
          final sId = st['id'] as String;
          // 85% present, 10% absent, 5% excused
          final roll = _rnd.nextDouble();
          AttendanceStatus status = AttendanceStatus.present;
          if (roll > 0.90) {
            status = AttendanceStatus.absent;
          } else if (roll > 0.85) {
            status = AttendanceStatus.excused;
          }

          final recitation = status == AttendanceStatus.present ? (8 + _rnd.nextInt(3)).toDouble() : null;

          final record = AttendanceModel(
            id: _uuid.v4(),
            studentId: sId,
            groupId: gId,
            date: sessionDate,
            status: status,
            homeworkDone: status == AttendanceStatus.present && _rnd.nextBool(),
            note: status == AttendanceStatus.excused ? 'إذن مسبق' : '',
            recitationPoints: recitation,
          );

          await db.insert('attendance', record.toMap());
          totalRecords++;
        }
      }
    }

    return totalRecords;
  }

  /// 4. توليد اختبارات ودرجات واقعية
  static Future<int> generateMockExams({int examsPerGroup = 3}) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final groups = await db.query('groups');
    if (groups.isEmpty) return 0;

    int totalExams = 0;
    final examTitles = ['اختبار شهري أول', 'كويز سريع 1', 'امتحان نصف الفصل', 'اختبار شامل', 'تقييم واجبات'];

    for (final g in groups) {
      final gId = g['id'] as String;
      final gSubject = g['subject'] as String? ?? 'مادة';
      final students = await db.query('students', where: 'group_id = ?', whereArgs: [gId]);

      for (int e = 0; e < examsPerGroup; e++) {
        final totalMarks = [20.0, 30.0, 50.0, 100.0][_rnd.nextInt(4)];
        final examId = _uuid.v4();
        final examDate = DateTime.now().subtract(Duration(days: (e * 10) + 2));

        final exam = ExamModel(
          id: examId,
          groupId: gId,
          name: '${examTitles[e % examTitles.length]} - $gSubject',
          totalMarks: totalMarks,
          date: examDate,
        );

        await db.insert('exams', exam.toMap());
        totalExams++;

        // Add scores for each student
        for (final st in students) {
          final sId = st['id'] as String;
          // Score between 60% and 100%
          final percentage = 0.55 + (_rnd.nextDouble() * 0.45);
          final studentScore = (totalMarks * percentage).roundToDouble();

          await db.insert('exam_results', {
            'id': _uuid.v4(),
            'exam_id': examId,
            'student_id': sId,
            'marks': studentScore,
          });
        }
      }
    }

    return totalExams;
  }

  /// 5. توليد مدفوعات تجريبية
  static Future<int> generateMockPayments() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final students = await db.query('students');
    if (students.isEmpty) return 0;

    int totalPayments = 0;

    for (final st in students) {
      final sId = st['id'] as String;
      final gId = st['group_id'] as String;

      final isPaid = _rnd.nextDouble() < 0.75;
      if (isPaid) {
        final payment = PaymentModel(
          id: _uuid.v4(),
          studentId: sId,
          groupId: gId,
          amount: 200.0,
          totalDue: 200.0,
          type: PaymentType.full,
          date: DateTime.now().subtract(Duration(days: _rnd.nextInt(20))),
          month: _rnd.nextInt(12) + 1,
          year: DateTime.now().year,
        );

        await db.insert('payments', payment.toMap());
        totalPayments++;
      }
    }

    return totalPayments;
  }

  /// 6. سيناريوهات متكاملة جاهزة
  static Future<Map<String, int>> generateFullScenario([String type = 'standard']) async {
    int groupsCount = 5;
    int studentsCount = 50;

    if (type == 'megaCenter') {
      groupsCount = 20;
      studentsCount = 350;
    } else if (type == 'school') {
      groupsCount = 12;
      studentsCount = 200;
    } else if (type == 'onlineAcademy') {
      groupsCount = 6;
      studentsCount = 80;
    } else if (type == 'stressTest') {
      groupsCount = 40;
      studentsCount = 800;
    }

    final groups = await generateMockGroups(groupsCount);
    final students = await generateMockStudents(
      count: studentsCount,
      targetGroupIds: groups.map((g) => g.id).toList(),
    );
    final attendanceCount = await generateMockAttendanceHistory(sessionsCount: 4);
    final examsCount = await generateMockExams(examsPerGroup: 2);
    final paymentsCount = await generateMockPayments();

    return {
      'groups': groups.length,
      'students': students.length,
      'attendance': attendanceCount,
      'exams': examsCount,
      'payments': paymentsCount,
    };
  }

  /// 7. استرجاع إحصائيات قاعدة البيانات
  static Future<Map<String, int>> getDatabaseStats() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final groupsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM groups')) ?? 0;
    final studentsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM students')) ?? 0;
    final attendanceCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM attendance')) ?? 0;
    final examsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM exams')) ?? 0;
    final paymentsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM payments')) ?? 0;
    final notesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM notes')) ?? 0;

    return {
      'groups': groupsCount,
      'students': studentsCount,
      'attendance': attendanceCount,
      'exams': examsCount,
      'payments': paymentsCount,
      'notes': notesCount,
    };
  }

  /// 8. تفريغ الجداول أو إعادة الضبط
  static Future<void> clearAllData() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    await db.delete('students');
    await db.delete('groups');
    await db.delete('attendance');
    await db.delete('exams');
    await db.delete('exam_results');
    await db.delete('payments');
    await db.delete('notes');
  }

  /// 9. توليد حزمة اختبار الإشعارات (46 مجموعة متتابعة كل 31 دقيقة مدتها 30 دقيقة على مدار 24 ساعة)
  static Future<int> generateNotificationTestBatch({
    bool startFromCurrentTime = true,
    int count = 46,
  }) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final now = DateTime.now();
    final List<GroupModel> createdGroups = [];

    // نبدأ من اللحظة الحالية + دقيقتين أو من بداية اليوم، لجدولة الحصص بتتابع 31 دقيقة
    DateTime cursorTime = startFromCurrentTime
        ? now.add(const Duration(minutes: 2))
        : DateTime(now.year, now.month, now.day, 0, 0);

    for (int i = 0; i < count; i++) {
      final groupId = 'test_notif_${_uuid.v4().substring(0, 8)}';
      final arabicDay = AppDateUtils.arabicDayName(cursorTime);
      final timeStr = '${cursorTime.hour.toString().padLeft(2, '0')}:${cursorTime.minute.toString().padLeft(2, '0')}';
      final subject = _subjects[i % _subjects.length];
      final formattedTime12 = ArabicNumbers.formatTime12(timeStr);

      final group = GroupModel(
        id: groupId,
        name: 'مجموعة اختبار #${i + 1} ($formattedTime12)',
        type: GroupType.center,
        subject: subject,
        days: [
          GroupDay(
            day: arabicDay,
            time: timeStr,
            durationMinutes: 30, // مدة الحصة 30 دقيقة
          ),
        ],
        monthlyPrice: 300,
        sessionPrice: 50,
        onlinePlatform: 'سنتر الاختبار الذكي',
        status: GroupStatus.active,
        createdAt: now,
      );

      await db.insert(
        AppConstants.tableGroups,
        group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // إضافة 3 طلاب تجريبيين لكل مجموعة للاختبار الشامل
      for (int s = 0; s < 3; s++) {
        final student = StudentModel(
          id: 'test_std_${_uuid.v4().substring(0, 8)}',
          name: _randomStudentName(),
          phone: _randomPhone(),
          parentPhone: _randomPhone(),
          groupId: groupId,
          level: 5,
          points: 10,
          status: StudentStatus.active,
          createdAt: now,
        );
        await db.insert(
          AppConstants.tableStudents,
          student.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      createdGroups.add(group);
      cursorTime = cursorTime.add(const Duration(minutes: 31)); // كل 31 دقيقة مجموعة
    }

    return createdGroups.length;
  }

  /// حذف جميع مجموعات وطلاب حزمة اختبار الإشعارات
  static Future<int> clearNotificationTestBatch() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    await db.delete(
      AppConstants.tableStudents,
      where: "id LIKE 'test_std_%' OR group_id LIKE 'test_notif_%'",
    );
    final deletedGroups = await db.delete(
      AppConstants.tableGroups,
      where: "id LIKE 'test_notif_%'",
    );
    return deletedGroups;
  }
}
