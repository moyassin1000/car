class WorkSettings {
  final double myShare;
  final double partner1Share;
  final double partner2Share;
  final double adminNormalRate;
  final double adminAfterMaintenanceRate;
  final double defaultGarage;
  final String privateDriver;
  final List<String> driverChoices;

  const WorkSettings({
    required this.myShare,
    required this.partner1Share,
    required this.partner2Share,
    required this.adminNormalRate,
    required this.adminAfterMaintenanceRate,
    required this.defaultGarage,
    required this.privateDriver,
    required this.driverChoices,
  });

  factory WorkSettings.defaults() => const WorkSettings(
        myShare: 0.20,
        partner1Share: 0.40,
        partner2Share: 0.40,
        adminNormalRate: 0.10,
        adminAfterMaintenanceRate: 0.15,
        defaultGarage: 25,
        privateDriver: 'مصطفى',
        driverChoices: ['مصطفى', 'مدحت', 'شخص آخر', 'بابا'],
      );

  WorkSettings copyWith({
    double? myShare,
    double? partner1Share,
    double? partner2Share,
    double? adminNormalRate,
    double? adminAfterMaintenanceRate,
    double? defaultGarage,
    String? privateDriver,
    List<String>? driverChoices,
  }) {
    return WorkSettings(
      myShare: myShare ?? this.myShare,
      partner1Share: partner1Share ?? this.partner1Share,
      partner2Share: partner2Share ?? this.partner2Share,
      adminNormalRate: adminNormalRate ?? this.adminNormalRate,
      adminAfterMaintenanceRate: adminAfterMaintenanceRate ?? this.adminAfterMaintenanceRate,
      defaultGarage: defaultGarage ?? this.defaultGarage,
      privateDriver: privateDriver ?? this.privateDriver,
      driverChoices: driverChoices ?? this.driverChoices,
    );
  }
}
