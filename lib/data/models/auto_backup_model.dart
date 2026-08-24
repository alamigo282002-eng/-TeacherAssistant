import 'dart:convert';
import '../../core/constants/app_constants.dart';

class AutoBackupModel {
  final int id;
  final bool isEnabled;
  final BackupFrequency frequency;
  final DateTime? lastBackupDate;
  final int keepCount;
  final String backupPath;

  AutoBackupModel({
    this.id = 1,
    this.isEnabled = false,
    this.frequency = BackupFrequency.weekly,
    this.lastBackupDate,
    this.keepCount = 5,
    this.backupPath = '',
  });

  AutoBackupModel copyWith({
    int? id,
    bool? isEnabled,
    BackupFrequency? frequency,
    DateTime? lastBackupDate,
    int? keepCount,
    String? backupPath,
  }) {
    return AutoBackupModel(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      frequency: frequency ?? this.frequency,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      keepCount: keepCount ?? this.keepCount,
      backupPath: backupPath ?? this.backupPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'is_enabled': isEnabled ? 1 : 0,
      'frequency': frequency.name,
      'last_backup_date': lastBackupDate?.toIso8601String(),
      'keep_count': keepCount,
      'backup_path': backupPath,
    };
  }

  factory AutoBackupModel.fromMap(Map<String, dynamic> map) {
    return AutoBackupModel(
      id: map['id'] as int? ?? 1,
      isEnabled: (map['is_enabled'] as int? ?? 0) == 1,
      frequency: BackupFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => BackupFrequency.weekly,
      ),
      lastBackupDate: map['last_backup_date'] != null 
          ? DateTime.parse(map['last_backup_date'] as String) 
          : null,
      keepCount: map['keep_count'] as int? ?? 5,
      backupPath: map['backup_path'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AutoBackupModel.fromJson(String source) => AutoBackupModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
