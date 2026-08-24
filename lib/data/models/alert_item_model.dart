import 'package:flutter/material.dart';

enum AlertCategory {
  session,      // ⏰ تذكير قبل الحصة بـ 15 دقيقة
  sessionEnd,   // 📋 تنبيه انتهاء وقت الحصة لرصد الغياب
  note,         // 📝 تذكير بملاحظة أو مهمة مجدولة
  payment,      // 💰 تذكير سداد اشتراكات شهرية
  exam,         // 📊 تذكير بموعد اختبار مجدول
  general,      // 🔔 تنبيه عام
}

class AlertItemModel {
  final String id;
  final int notifId;
  final AlertCategory category;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final DateTime eventTime;
  final String? targetId;
  final String? targetName;
  final String badgeText;
  final IconData icon;
  final Color color;

  const AlertItemModel({
    required this.id,
    required this.notifId,
    required this.category,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.eventTime,
    this.targetId,
    this.targetName,
    required this.badgeText,
    required this.icon,
    required this.color,
  });

  bool get isUpcoming => scheduledTime.isAfter(DateTime.now());
  Duration get timeUntil => scheduledTime.difference(DateTime.now());
}
