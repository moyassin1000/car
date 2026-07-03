import 'package:shared_preferences/shared_preferences.dart';

import '../models/work_settings.dart';
import '../utils/app_constants.dart';

class SettingsService {
  static const _themeKey = 'theme_mode_name';
  static const _appNameKey = 'app_name';
  static const _myShareKey = 'my_share';
  static const _partner1ShareKey = 'partner1_share';
  static const _partner2ShareKey = 'partner2_share';
  static const _adminNormalKey = 'admin_normal_rate';
  static const _adminAfterMaintenanceKey = 'admin_after_maintenance_rate';
  static const _defaultGarageKey = 'default_garage';
  static const _privateDriverKey = 'private_driver';
  static const _driverChoicesKey = 'driver_choices';
  static const _autoDriveBackupKey = 'auto_drive_backup_enabled';
  static const _lastDriveSyncKey = 'last_drive_sync_at';

  Future<String> getThemeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? AppConstants.premiumTheme;
  }

  Future<void> setThemeName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, value);
  }

  Future<String> getAppName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_appNameKey) ?? AppConstants.defaultAppName;
  }

  Future<void> setAppName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final name = value.trim().isEmpty ? AppConstants.defaultAppName : value.trim();
    await prefs.setString(_appNameKey, name);
  }

  Future<WorkSettings> getWorkSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = WorkSettings.defaults();
    final choices = prefs.getStringList(_driverChoicesKey) ?? defaults.driverChoices;
    return WorkSettings(
      myShare: prefs.getDouble(_myShareKey) ?? defaults.myShare,
      partner1Share: prefs.getDouble(_partner1ShareKey) ?? defaults.partner1Share,
      partner2Share: prefs.getDouble(_partner2ShareKey) ?? defaults.partner2Share,
      adminNormalRate: prefs.getDouble(_adminNormalKey) ?? defaults.adminNormalRate,
      adminAfterMaintenanceRate: prefs.getDouble(_adminAfterMaintenanceKey) ?? defaults.adminAfterMaintenanceRate,
      defaultGarage: prefs.getDouble(_defaultGarageKey) ?? defaults.defaultGarage,
      privateDriver: prefs.getString(_privateDriverKey) ?? defaults.privateDriver,
      driverChoices: choices,
    );
  }

  Future<void> setWorkSettings(WorkSettings value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_myShareKey, value.myShare);
    await prefs.setDouble(_partner1ShareKey, value.partner1Share);
    await prefs.setDouble(_partner2ShareKey, value.partner2Share);
    await prefs.setDouble(_adminNormalKey, value.adminNormalRate);
    await prefs.setDouble(_adminAfterMaintenanceKey, value.adminAfterMaintenanceRate);
    await prefs.setDouble(_defaultGarageKey, value.defaultGarage);
    await prefs.setString(_privateDriverKey, value.privateDriver.trim().isEmpty ? 'مصطفى' : value.privateDriver.trim());
    await prefs.setStringList(_driverChoicesKey, value.driverChoices.where((e) => e.trim().isNotEmpty).map((e) => e.trim()).toSet().toList());
  }

  Future<bool> getAutoDriveBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoDriveBackupKey) ?? false;
  }

  Future<void> setAutoDriveBackupEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoDriveBackupKey, value);
  }

  Future<String?> getLastDriveSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastDriveSyncKey);
  }

  Future<void> setLastDriveSyncAt(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDriveSyncKey, value);
  }
}
