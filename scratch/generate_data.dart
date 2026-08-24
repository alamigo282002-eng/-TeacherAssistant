// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final rand = Random();
  final daysAr = ["السبت", "الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة"];
  final subjects = ["Gem", "المعاصر", "أخرى"];
  final types = ["سنتر", "أونلاين", "أخرى"];
  
  final firstNames = ["أحمد", "محمد", "محمود", "عمر", "علي", "يوسف", "حسن", "حسين", "عبد الله", "مصطفى", "إبراهيم", "فاطمة", "مريم", "سارة", "نور", "ملك", "حبيبة", "شهد", "ندى", "آية", "رؤى", "زياد", "كريم", "ياسين", "سيف", "خالد", "مازن", "سالم"];
  final lastNames = ["السباعي", "النجار", "الحداد", "المصري", "المهندس", "السيد", "محمود", "علي", "إبراهيم", "حسن", "حسين", "كمال", "سعيد", "صالح", "علام", "منصور", "زكي", "رضوان"];

  String uuid() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(RegExp(r'[xy]'), (match) {
      final r = rand.nextInt(16);
      final v = match.group(0) == 'x' ? r : (r & 0x3 | 0x8);
      return v.toRadixString(16);
    });
  }

  final groups = [];
  final students = [];
  final now = DateTime.now().toIso8601String();

  for (int i = 1; i <= 15; i++) {
    final gId = uuid();
    final d1 = daysAr[rand.nextInt(daysAr.length)];
    var d2 = daysAr[rand.nextInt(daysAr.length)];
    while (d1 == d2) {
      d2 = daysAr[rand.nextInt(daysAr.length)];
    }

    final daysJson = jsonEncode([
      {"day": d1, "time": "${(rand.nextInt(8) + 12).toString().padLeft(2, '0')}:00"},
      {"day": d2, "time": "${(rand.nextInt(8) + 12).toString().padLeft(2, '0')}:00"}
    ]);

    final grades = ['الأول', 'الثاني', 'الثالث'];
    groups.add({
      "id": gId,
      "name": "المجموعة رقم $i - الصف ${grades[rand.nextInt(grades.length)]}",
      "type": types[rand.nextInt(types.length)],
      "subject": subjects[rand.nextInt(subjects.length)],
      "days": daysJson,
      "monthly_price": [150, 200, 250, 300][rand.nextInt(4)].toDouble(),
      "status": "نشطة",
      "created_at": now
    });

    final numStudents = rand.nextInt(16) + 15; // 15 to 30
    for (int j = 0; j < numStudents; j++) {
      final sId = uuid();
      final name = "${firstNames[rand.nextInt(firstNames.length)]} ${lastNames[rand.nextInt(lastNames.length)]}";
      final phone = "010${(rand.nextInt(90000000) + 10000000)}";
      final parent = "011${(rand.nextInt(90000000) + 10000000)}";

      students.add({
        "id": sId,
        "name": name,
        "phone": phone,
        "parent_phone": parent,
        "level": rand.nextInt(10) + 1,
        "group_id": gId,
        "notes": "",
        "points": rand.nextInt(50),
        "status": "نشط",
        "created_at": now
      });
    }
  }

  final data = {
    "groups": groups,
    "students": students,
    "attendance": [],
    "exams": [],
    "exam_results": [],
    "payments": []
  };

  final file = File(r"C:\Users\AM\Desktop\backup_test.json");
  file.writeAsStringSync(jsonEncode(data));
  print("Done!");
}
