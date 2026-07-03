import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/work_settings.dart';
import '../providers/app_provider.dart';
import '../services/drive_backup_service.dart';
import '../services/export_service.dart';
import '../utils/app_constants.dart';
import '../widgets/app_drawer.dart';
import '../widgets/premium_card.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _appName = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _myShare = TextEditingController();
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  final _admin = TextEditingController();
  final _adminAfter = TextEditingController();
  final _garage = TextEditingController();
  final _privateDriver = TextEditingController();
  final _drivers = TextEditingController();
  final _exportService = ExportService();
  final _driveService = DriveBackupService();
  bool _loadedSettings = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<AppProvider>();
    _appName.text = provider.appName;
    if (!_loadedSettings) {
      _fillWorkSettings(provider.workSettings);
      _loadedSettings = true;
    }
  }

  void _fillWorkSettings(WorkSettings s) {
    _myShare.text = _percent(s.myShare);
    _p1.text = _percent(s.partner1Share);
    _p2.text = _percent(s.partner2Share);
    _admin.text = _percent(s.adminNormalRate);
    _adminAfter.text = _percent(s.adminAfterMaintenanceRate);
    _garage.text = s.defaultGarage.toStringAsFixed(0);
    _privateDriver.text = s.privateDriver;
    _drivers.text = s.driverChoices.join(',');
  }

  @override
  void dispose() {
    for (final c in [_appName, _password, _confirmPassword, _myShare, _p1, _p2, _admin, _adminAfter, _garage, _privateDriver, _drivers]) {
      c.dispose();
    }
    super.dispose();
  }

  String _percent(double v) => (v * 100).toStringAsFixed(v * 100 == (v * 100).roundToDouble() ? 0 : 2);
  double _asRate(TextEditingController c) => (double.tryParse(c.text.replaceAll(',', '.').trim()) ?? 0) / 100;
  double _asDouble(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.').trim()) ?? 0;

  Future<void> _saveAppName() async {
    await context.read<AppProvider>().setAppName(_appName.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ اسم التطبيق داخل الواجهة')));
  }

  Future<void> _saveWorkSettings() async {
    final settings = WorkSettings(
      myShare: _asRate(_myShare),
      partner1Share: _asRate(_p1),
      partner2Share: _asRate(_p2),
      adminNormalRate: _asRate(_admin),
      adminAfterMaintenanceRate: _asRate(_adminAfter),
      defaultGarage: _asDouble(_garage),
      privateDriver: _privateDriver.text.trim().isEmpty ? 'مصطفى' : _privateDriver.text.trim(),
      driverChoices: _drivers.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    );
    await context.read<AppProvider>().setWorkSettings(settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ إعدادات الشيت')));
  }

  Future<void> _changePassword() async {
    if (_password.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور يجب ألا تقل عن 4 أحرف')));
      return;
    }
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تأكيد كلمة المرور غير مطابق')));
      return;
    }
    await context.read<AppProvider>().changePassword(_password.text);
    _password.clear();
    _confirmPassword.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور')));
  }

  Future<void> _backup() async {
    final path = await DatabaseHelper.instance.backupDatabase();
    await _exportService.shareFile(File(path), text: 'نسخة احتياطية من بيانات إدارة الشغل');
  }

  Future<void> _restore() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
    final path = picked?.files.single.path;
    if (path == null) return;
    await DatabaseHelper.instance.restoreDatabase(path);
    if (!mounted) return;
    await context.read<AppProvider>().refreshDashboard();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استرجاع النسخة الاحتياطية')));
  }

  Future<void> _connectDrive() async {
    try {
      final message = await _driveService.connect();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      _showInfo('ربط Google Drive', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _uploadDriveNow() async {
    try {
      final path = await DatabaseHelper.instance.backupDatabase();
      final message = await _driveService.uploadBackup(File(path));
      if (!mounted) return;
      await context.read<AppProvider>().markDriveSyncNow();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      _showInfo('رفع Google Drive', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('مسح كل البيانات'),
        content: const Text('هل أنت متأكد؟ لا يمكن التراجع عن هذه العملية إلا إذا كان لديك نسخة احتياطية.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('مسح'))],
      ),
    );
    if (confirm == true) {
      await context.read<AppProvider>().clearAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم مسح كل البيانات')));
    }
  }

  Future<void> _logout() async {
    await context.read<AppProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, LoginScreen.routeName, (_) => false);
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(title: Text(title), content: Text(message), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تمام'))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          PremiumCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('اسم التطبيق', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextField(controller: _appName, decoration: const InputDecoration(prefixIcon: Icon(Icons.drive_file_rename_outline), labelText: 'اسم التطبيق')),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: _saveAppName, icon: const Icon(Icons.save), label: const Text('حفظ الاسم')),
            ]),
          ),
          const SizedBox(height: 14),
          PremiumCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('الثيم', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              RadioListTile<String>(value: AppConstants.premiumTheme, groupValue: provider.themeName, onChanged: (v) => provider.setTheme(v!), title: const Text('Premium Mode')),
              RadioListTile<String>(value: AppConstants.darkTheme, groupValue: provider.themeName, onChanged: (v) => provider.setTheme(v!), title: const Text('Dark Mode')),
              RadioListTile<String>(value: AppConstants.lightTheme, groupValue: provider.themeName, onChanged: (v) => provider.setTheme(v!), title: const Text('Light Mode')),
            ]),
          ),
          const SizedBox(height: 14),
          PremiumCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('إعدادات الشيت والحسابات', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _two(_field(_myShare, 'نسبة نصيبي %'), _field(_p1, 'نسبة شريك 1 %')),
              const SizedBox(height: 12),
              _two(_field(_p2, 'نسبة شريك 2 %'), _field(_garage, 'الجراج الافتراضي')),
              const SizedBox(height: 12),
              _two(_field(_admin, 'الإدارة العادية %'), _field(_adminAfter, 'إدارة بعد صيانة %')),
              const SizedBox(height: 12),
              TextField(controller: _privateDriver, decoration: const InputDecoration(labelText: 'السائق الخاص بي', prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 12),
              TextField(controller: _drivers, decoration: const InputDecoration(labelText: 'اختيارات السائقين مفصولة بفاصلة', prefixIcon: Icon(Icons.list))),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: _saveWorkSettings, icon: const Icon(Icons.save), label: const Text('حفظ إعدادات الحسابات')),
            ]),
          ),
          const SizedBox(height: 14),
          PremiumCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Google Drive', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('الربط الرسمي سيتم عبر Google Sign-In وDrive API بدون طلب كلمة مرور Gmail. يحتاج إعداد Google Cloud قبل التفعيل الكامل.'),
              const SizedBox(height: 12),
              SwitchListTile(value: provider.autoDriveBackupEnabled, onChanged: provider.setAutoDriveBackupEnabled, title: const Text('تفعيل النسخ الاحتياطي التلقائي عند توفر الإنترنت')),
              Text('آخر مزامنة: ${provider.lastDriveSyncAt ?? 'لم تتم بعد'}'),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: _connectDrive, icon: const Icon(Icons.cloud_done_rounded), label: const Text('ربط Google Drive')),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: _uploadDriveNow, icon: const Icon(Icons.cloud_upload_rounded), label: const Text('رفع نسخة الآن')),
            ]),
          ),
          const SizedBox(height: 14),
          PremiumCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('تغيير كلمة المرور', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextField(controller: _password, obscureText: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.lock), labelText: 'كلمة المرور الجديدة')),
              const SizedBox(height: 12),
              TextField(controller: _confirmPassword, obscureText: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.verified_user), labelText: 'تأكيد كلمة المرور')),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: _changePassword, icon: const Icon(Icons.password), label: const Text('تغيير كلمة المرور')),
            ]),
          ),
          const SizedBox(height: 14),
          PremiumCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('البيانات', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: _backup, icon: const Icon(Icons.backup), label: const Text('نسخ احتياطي ومشاركة')),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: _restore, icon: const Icon(Icons.restore), label: const Text('استرجاع نسخة احتياطية')),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(onPressed: _clearAll, icon: const Icon(Icons.delete_forever), label: const Text('مسح كل البيانات')),
            ]),
          ),
          const SizedBox(height: 14),
          PremiumCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: const [
              Text('حول التطبيق', style: TextStyle(fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text('إدارة الشغل - الإصدار 2.0'),
              Text('تم إنشاء التطبيق بواسطة M.R.Yassin'),
            ]),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label));
  Widget _two(Widget a, Widget b) => Row(children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)]);
}
