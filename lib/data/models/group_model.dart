import 'dart:convert';
import '../../core/constants/app_constants.dart';

class GroupDay {
  final String day;
  final String time; // HH:MM
  final int durationMinutes; // Default 60 minutes (1 hour)

  const GroupDay({
    required this.day,
    required this.time,
    this.durationMinutes = 60,
  });

  Map<String, dynamic> toMap() => {
    'day': day,
    'time': time,
    'duration': durationMinutes,
  };

  factory GroupDay.fromMap(Map<String, dynamic> map) => GroupDay(
    day: map['day'] as String,
    time: map['time'] as String,
    durationMinutes: (map['duration'] as num?)?.toInt() ?? 60,
  );

  String toJson() => jsonEncode(toMap());

  int get startMinutes {
    try {
      final clean = time.replaceAll(RegExp(r'[^0-9:]'), '').trim();
      final parts = clean.split(':');
      if (parts.length >= 2) {
        int h = int.parse(parts[0]);
        int m = int.parse(parts[1]);
        if (time.contains('م') && h < 12) h += 12;
        if (time.contains('ص') && h == 12) h = 0;
        return h * 60 + m;
      }
    } catch (_) {}
    return 17 * 60; // fallback 5:00 PM
  }

  int get endMinutes => startMinutes + durationMinutes;

  bool overlapsWith(GroupDay other) {
    if (day != other.day) return false;
    return startMinutes < other.endMinutes && endMinutes > other.startMinutes;
  }
}

class GroupModel {
  final String id;
  final String name;
  final GroupType type;
  final String? subject; // Optional subject from settings.mySubjects
  final List<GroupDay> days;
  final String paymentMode; // 'monthly' | 'per_session'
  final double monthlyPrice;
  final double sessionPrice;
  final String? whatsappLink; // WhatsApp Group invite URL
  final String? onlinePlatform; // 'teams' | 'zoom' | 'meet' | 'custom'
  final String? onlineMeetingUrl; // Zoom / Teams meeting link
  final GroupStatus status;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.type,
    this.subject,
    required this.days,
    this.paymentMode = 'monthly',
    this.monthlyPrice = 0,
    this.sessionPrice = 0,
    this.whatsappLink,
    this.onlinePlatform,
    this.onlineMeetingUrl,
    this.status = GroupStatus.active,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.label,
      'subject': (subject != null && subject!.isNotEmpty) ? subject! : 'عام',
      'days': jsonEncode(days.map((d) => d.toMap()).toList()),
      'payment_mode': paymentMode,
      'monthly_price': monthlyPrice,
      'session_price': sessionPrice,
      'whatsapp_link': whatsappLink ?? '',
      'online_platform': onlinePlatform ?? '',
      'online_meeting_url': onlineMeetingUrl ?? '',
      'status': status.label,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    final daysRaw = map['days'] as String? ?? '[]';
    final daysList = (jsonDecode(daysRaw) as List)
        .map((d) => GroupDay.fromMap(Map<String, dynamic>.from(d)))
        .toList();
    return GroupModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: GroupTypeExt.fromLabel(map['type'] as String),
      subject: map['subject'] as String?,
      days: daysList,
      paymentMode: map['payment_mode'] as String? ?? 'monthly',
      monthlyPrice: (map['monthly_price'] as num?)?.toDouble() ?? 0,
      sessionPrice: (map['session_price'] as num?)?.toDouble() ?? 0,
      whatsappLink: map['whatsapp_link'] as String?,
      onlinePlatform: map['online_platform'] as String?,
      onlineMeetingUrl: map['online_meeting_url'] as String?,
      status: GroupStatusExt.fromLabel(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  GroupModel copyWith({
    String? id,
    String? name,
    GroupType? type,
    String? subject,
    List<GroupDay>? days,
    String? paymentMode,
    double? monthlyPrice,
    double? sessionPrice,
    String? whatsappLink,
    String? onlinePlatform,
    String? onlineMeetingUrl,
    GroupStatus? status,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      days: days ?? this.days,
      paymentMode: paymentMode ?? this.paymentMode,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      sessionPrice: sessionPrice ?? this.sessionPrice,
      whatsappLink: whatsappLink ?? this.whatsappLink,
      onlinePlatform: onlinePlatform ?? this.onlinePlatform,
      onlineMeetingUrl: onlineMeetingUrl ?? this.onlineMeetingUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns true if this group is scheduled on the given Arabic day name
  bool isScheduledOn(String arabicDayName) {
    return days.any((d) => d.day == arabicDayName);
  }

  /// Returns scheduled time for a given day, or null
  String? timeForDay(String arabicDayName) {
    try {
      return days.firstWhere((d) => d.day == arabicDayName).time;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if this group has a valid WhatsApp link
  bool get hasWhatsAppLink =>
      whatsappLink != null && whatsappLink!.trim().isNotEmpty;

  /// Returns true if this group is an online group
  bool get isOnline => type == GroupType.online;

  /// Returns true if this group has an active online meeting URL
  bool get hasOnlineMeeting =>
      onlineMeetingUrl != null && onlineMeetingUrl!.trim().isNotEmpty;

  /// Returns true if this group is per session
  bool get isPerSession => paymentMode == 'per_session';

  /// Returns effective base price based on payment mode
  double get basePrice => isPerSession ? sessionPrice : monthlyPrice;
}
