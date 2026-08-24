import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/app_lock_model.dart';
import '../../data/repositories/app_lock_repository.dart';

class LockProvider extends ChangeNotifier {
  final AppLockRepository _repo = AppLockRepository();
  AppLockModel _settings = AppLockModel();
  bool _isUnlocked = false;
  bool _initialized = false;

  AppLockModel get settings => _settings;
  bool get isLockEnabled => _settings.isEnabled;
  bool get useBiometric => _settings.useBiometric;
  bool get isLocked => _settings.isEnabled && !_isUnlocked;
  bool get isUnlocked => _isUnlocked;
  bool get initialized => _initialized;
  String? get currentPin => _settings.pinHash;
  String? get securityQuestion => _settings.securityQuestion;
  String? get securityAnswer => _settings.securityAnswer;
  bool get hasSecurityQuestion =>
      _settings.securityQuestion != null && _settings.securityQuestion!.trim().isNotEmpty;

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefEnabled = prefs.getBool('app_lock_enabled');
      final prefPin = prefs.getString('app_lock_pin');
      final prefBio = prefs.getBool('app_lock_biometric');
      final prefSecQ = prefs.getString('app_lock_sec_q');
      final prefSecA = prefs.getString('app_lock_sec_a');

      final dbSettings = await _repo.getLockSettings();

      final effectiveQ = (dbSettings.securityQuestion != null && dbSettings.securityQuestion!.isNotEmpty)
          ? dbSettings.securityQuestion
          : prefSecQ;
      final effectiveA = (dbSettings.securityAnswer != null && dbSettings.securityAnswer!.isNotEmpty)
          ? dbSettings.securityAnswer
          : prefSecA;

      // Prefer DB settings if available, else fallback to prefs
      if (dbSettings.isEnabled || (prefEnabled ?? false)) {
        _settings = AppLockModel(
          isEnabled: dbSettings.isEnabled || (prefEnabled ?? false),
          pinHash: (dbSettings.pinHash != null && dbSettings.pinHash!.isNotEmpty)
              ? dbSettings.pinHash
              : prefPin,
          useBiometric: dbSettings.useBiometric || (prefBio ?? false),
          securityQuestion: effectiveQ,
          securityAnswer: effectiveA,
        );
      } else {
        _settings = dbSettings.copyWith(
          securityQuestion: effectiveQ,
          securityAnswer: effectiveA,
        );
      }
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final isEn = prefs.getBool('app_lock_enabled') ?? false;
        final pin = prefs.getString('app_lock_pin');
        final bio = prefs.getBool('app_lock_biometric') ?? false;
        final secQ = prefs.getString('app_lock_sec_q');
        final secA = prefs.getString('app_lock_sec_a');
        _settings = AppLockModel(
          isEnabled: isEn,
          pinHash: pin,
          useBiometric: bio,
          securityQuestion: secQ,
          securityAnswer: secA,
        );
      } catch (_) {}
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> enableLock({
    required String pin,
    required bool useBiometric,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    _settings = _settings.copyWith(
      isEnabled: true,
      pinHash: pin,
      useBiometric: useBiometric,
      securityQuestion: securityQuestion,
      securityAnswer: securityAnswer,
    );

    // Save to SharedPreferences for instant sync
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_lock_enabled', true);
      await prefs.setString('app_lock_pin', pin);
      await prefs.setBool('app_lock_biometric', useBiometric);
      if (securityQuestion != null && securityQuestion.isNotEmpty) {
        await prefs.setString('app_lock_sec_q', securityQuestion);
      }
      if (securityAnswer != null && securityAnswer.isNotEmpty) {
        await prefs.setString('app_lock_sec_a', securityAnswer);
      }
    } catch (_) {}

    // Save to SQLite
    try {
      await _repo.saveLockSettings(_settings);
    } catch (_) {}

    _isUnlocked = true;
    notifyListeners();
  }

  Future<void> disableLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_lock_enabled', false);
      await prefs.remove('app_lock_pin');
      await prefs.setBool('app_lock_biometric', false);
      await prefs.remove('app_lock_sec_q');
      await prefs.remove('app_lock_sec_a');
    } catch (_) {}

    try {
      await _repo.clearLock();
    } catch (_) {}

    _settings = AppLockModel(isEnabled: false, pinHash: null, useBiometric: false);
    _isUnlocked = true;
    notifyListeners();
  }

  Future<void> updatePin(String newPin) async {
    _settings = _settings.copyWith(pinHash: newPin);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_lock_pin', newPin);
    } catch (_) {}

    try {
      await _repo.saveLockSettings(_settings);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> setBiometric(bool enabled) async {
    _settings = _settings.copyWith(useBiometric: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_lock_biometric', enabled);
    } catch (_) {}

    try {
      await _repo.saveLockSettings(_settings);
    } catch (_) {}

    notifyListeners();
  }

  bool unlockWithPin(String pin) {
    if (_settings.pinHash != null && _settings.pinHash == pin.trim()) {
      _isUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool verifySecurityAnswer(String answer) {
    final expected = _settings.securityAnswer?.trim().toLowerCase();
    if (expected == null || expected.isEmpty) return false;
    return expected == answer.trim().toLowerCase();
  }

  Future<bool> resetPinWithSecurityAnswer({
    required String answer,
    required String newPin,
  }) async {
    if (verifySecurityAnswer(answer)) {
      await updatePin(newPin);
      _isUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void unlockBiometric() {
    _isUnlocked = true;
    notifyListeners();
  }

  void unlockDirectly() {
    _isUnlocked = true;
    notifyListeners();
  }

  void lock() {
    if (_settings.isEnabled) {
      _isUnlocked = false;
      notifyListeners();
    }
  }
}
