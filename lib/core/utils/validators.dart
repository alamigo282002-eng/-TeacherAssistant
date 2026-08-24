class AppValidators {
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName مطلوب' : 'هذا الحقل مطلوب';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.length < 10) return 'رقم الهاتف غير صحيح';
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(cleaned)) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  static String? requiredPhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'رقم الهاتف مطلوب';
    return phone(value);
  }

  static String? positiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName مطلوب' : 'هذا الحقل مطلوب';
    }
    final n = double.tryParse(value);
    if (n == null || n <= 0) return 'يجب أن يكون رقم صحيح أكبر من صفر';
    return null;
  }

  static String? marks(String? value, double totalMarks) {
    if (value == null || value.trim().isEmpty) return null; // marks are optional
    final n = double.tryParse(value);
    if (n == null || n < 0) return 'الدرجة يجب أن تكون 0 أو أكبر';
    if (n > totalMarks) return 'الدرجة لا يمكن أن تتجاوز $totalMarks';
    return null;
  }

  /// Clean phone number for WhatsApp/calls (Egyptian format)
  static String cleanPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = '2$cleaned'; // Egypt country code
    } else if (!cleaned.startsWith('+') && !cleaned.startsWith('2')) {
      cleaned = '2$cleaned';
    }
    return cleaned.startsWith('+') ? cleaned.substring(1) : cleaned;
  }
}
