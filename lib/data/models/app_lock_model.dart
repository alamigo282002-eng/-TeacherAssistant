import 'dart:convert';

class AppLockModel {
  final int id;
  final bool isEnabled;
  final String? pinHash;
  final bool useBiometric;
  final String? securityQuestion;
  final String? securityAnswer;

  AppLockModel({
    this.id = 1,
    this.isEnabled = false,
    this.pinHash,
    this.useBiometric = false,
    this.securityQuestion,
    this.securityAnswer,
  });

  AppLockModel copyWith({
    int? id,
    bool? isEnabled,
    String? pinHash,
    bool? useBiometric,
    String? securityQuestion,
    String? securityAnswer,
  }) {
    return AppLockModel(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      pinHash: pinHash ?? this.pinHash,
      useBiometric: useBiometric ?? this.useBiometric,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswer: securityAnswer ?? this.securityAnswer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'is_locked': isEnabled ? 1 : 0,
      'lock_type': 'pin',
      'pin_hash': pinHash,
      'use_biometric': useBiometric ? 1 : 0,
      'security_question': securityQuestion,
      'security_answer': securityAnswer,
    };
  }

  factory AppLockModel.fromMap(Map<String, dynamic> map) {
    return AppLockModel(
      id: map['id'] as int? ?? 1,
      isEnabled: (map['is_locked'] as int? ?? 0) == 1,
      pinHash: map['pin_hash'] as String?,
      useBiometric: (map['use_biometric'] as int? ?? 0) == 1,
      securityQuestion: map['security_question'] as String?,
      securityAnswer: map['security_answer'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppLockModel.fromJson(String source) => AppLockModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
