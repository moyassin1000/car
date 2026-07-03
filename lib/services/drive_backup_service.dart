import 'dart:io';

class DriveBackupService {
  Future<String> connect() async {
    throw Exception('ربط Google Drive يحتاج إعداد Google Cloud وDrive API وOAuth Client Android. الزر موجود الآن تمهيدًا للربط الرسمي بدون طلب كلمة مرور Gmail.');
  }

  Future<String> uploadBackup(File file) async {
    throw Exception('رفع Google Drive غير مفعل بعد. استخدم النسخ الاحتياطي المحلي أو المشاركة الآن، وبعد إعداد Google Cloud سنفعل الرفع التلقائي.');
  }
}
