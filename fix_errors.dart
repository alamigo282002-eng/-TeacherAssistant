
import 'dart:io';

void replaceInFile(String path, String oldStr, String newStr) {
  var file = File(path);
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();
  content = content.replaceAll(oldStr, newStr);
  file.writeAsStringSync(content);
}

void main() {
  replaceInFile('lib/features/groups/groups_provider.dart', 'await _repo.delete(id);', 'await _repo.softDelete(id);');
  replaceInFile('lib/features/onboarding/onboarding_screen.dart', 'AppColors.textSecondary', 'AppColors.lightTextSecondary');
  replaceInFile('lib/features/splash/splash_screen.dart', 'AppColors.darkTextPrimary', 'AppColors.darkText');
  replaceInFile('lib/features/home/home_screen.dart', '_buildPaymentAlertBanner(isDark),', 'const SizedBox.shrink(),');
  replaceInFile('lib/features/home/home_screen.dart', '_buildLeaderboard(home, isDark),', 'const SizedBox.shrink(),');
  replaceInFile('lib/data/repositories/app_lock_repository.dart', 'lock.id)', 'lock.id.toString())');
  replaceInFile('lib/features/finance/payment_alert_screen.dart', 'p.type == PaymentType.paid || p.type == PaymentType.exempt', 'p.type == PaymentType.full');
  replaceInFile('lib/features/finance/payment_alert_screen.dart', 'AppColors.darkTextPrimary', 'AppColors.darkText');
  replaceInFile('lib/features/finance/payment_alert_screen.dart', 'AppColors.textSecondary', 'AppColors.lightTextSecondary');
  replaceInFile('lib/features/students/student_detail_screen.dart', 'AppColors.textSecondary', 'AppColors.lightTextSecondary');
  replaceInFile('lib/features/settings/trash_screen.dart', 'AppColors.textSecondary', 'AppColors.lightTextSecondary');
}

