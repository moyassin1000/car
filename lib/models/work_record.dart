import 'work_settings.dart';

class WorkRecord {
  final int? id;
  final String date;
  final String title;
  final double revenue;
  final double fuel;
  final double garage;
  final double maintenance;
  final double otherExpenses;
  final double paidFromPocket;
  final double driverCommission;
  final String driverName;
  final double driver2Commission;
  final String driver2Name;
  final double adminValue;
  final double cycleAmount;
  final double cycleDriverCommission;
  final String cycleDriverName;
  final double dayTotal;
  final String dayStatus;
  final double debtAmount;
  final double myPositionNet;
  final double partner1Debt;
  final double partner2Debt;
  final double myFinalShare;
  final double partner1FinalShare;
  final double partner2FinalShare;
  final double totalExpenses;
  final double netProfit;
  final String notes;
  final String createdAt;
  final String updatedAt;

  WorkRecord({
    this.id,
    required this.date,
    required this.title,
    required this.revenue,
    required this.fuel,
    required this.garage,
    required this.maintenance,
    required this.otherExpenses,
    required this.paidFromPocket,
    required this.driverCommission,
    required this.driverName,
    required this.driver2Commission,
    required this.driver2Name,
    required this.adminValue,
    required this.cycleAmount,
    required this.cycleDriverCommission,
    required this.cycleDriverName,
    required this.dayTotal,
    required this.dayStatus,
    required this.debtAmount,
    required this.myPositionNet,
    required this.partner1Debt,
    required this.partner2Debt,
    required this.myFinalShare,
    required this.partner1FinalShare,
    required this.partner2FinalShare,
    required this.totalExpenses,
    required this.netProfit,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkRecord.create({
    int? id,
    required String date,
    required String title,
    required double revenue,
    required double fuel,
    required double garage,
    required double maintenance,
    required double otherExpenses,
    required double paidFromPocket,
    required double driverCommission,
    required String driverName,
    required double driver2Commission,
    required String driver2Name,
    required double cycleAmount,
    required double cycleDriverCommission,
    required String cycleDriverName,
    required String notes,
    required WorkSettings settings,
    WorkRecord? previousRecord,
    String? createdAt,
  }) {
    final now = DateTime.now().toIso8601String();
    final prevTriggersHighAdmin = previousRecord != null &&
        previousRecord.revenue + previousRecord.cycleAmount == 0 &&
        (previousRecord.maintenance > 0 || previousRecord.otherExpenses > 0);
    final incomeBase = revenue + cycleAmount;
    final adminRate = prevTriggersHighAdmin ? settings.adminAfterMaintenanceRate : settings.adminNormalRate;
    final admin = incomeBase > 0 ? incomeBase * adminRate : 0.0;
    final dayTotal = incomeBase - fuel - garage - maintenance - otherExpenses - driverCommission - driver2Commission - admin - cycleDriverCommission;
    final status = dayTotal > 0 ? 'ربح' : (dayTotal < 0 ? 'مديونية' : 'تعادل');
    final debt = dayTotal < 0 ? dayTotal.abs() : 0.0;
    final myDebtShare = debt * settings.myShare;
    final partner1Debt = debt * settings.partner1Share;
    final partner2Debt = debt * settings.partner2Share;
    final privateDriver = settings.privateDriver.trim();
    final privateCommissions =
        (driverName.trim() == privateDriver ? driverCommission : 0.0) +
        (driver2Name.trim() == privateDriver ? driver2Commission : 0.0) +
        (cycleDriverName.trim() == privateDriver ? cycleDriverCommission : 0.0);
    final positiveShare = dayTotal > 0 ? dayTotal : 0.0;
    final myFinal = positiveShare * settings.myShare + admin + paidFromPocket - myDebtShare + privateCommissions;
    final p1Final = positiveShare * settings.partner1Share - partner1Debt;
    final p2Final = positiveShare * settings.partner2Share - partner2Debt;
    final expenses = fuel + garage + maintenance + otherExpenses + paidFromPocket + driverCommission + driver2Commission + cycleDriverCommission;

    return WorkRecord(
      id: id,
      date: date,
      title: title,
      revenue: revenue,
      fuel: fuel,
      garage: garage,
      maintenance: maintenance,
      otherExpenses: otherExpenses,
      paidFromPocket: paidFromPocket,
      driverCommission: driverCommission,
      driverName: driverName,
      driver2Commission: driver2Commission,
      driver2Name: driver2Name,
      adminValue: admin,
      cycleAmount: cycleAmount,
      cycleDriverCommission: cycleDriverCommission,
      cycleDriverName: cycleDriverName,
      dayTotal: dayTotal,
      dayStatus: status,
      debtAmount: debt,
      myPositionNet: debt > 0 ? paidFromPocket - myDebtShare : 0,
      partner1Debt: partner1Debt,
      partner2Debt: partner2Debt,
      myFinalShare: myFinal,
      partner1FinalShare: p1Final,
      partner2FinalShare: p2Final,
      totalExpenses: expenses,
      netProfit: dayTotal,
      notes: notes,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  WorkRecord copyWith({
    int? id,
    String? date,
    String? title,
    double? revenue,
    double? fuel,
    double? garage,
    double? maintenance,
    double? otherExpenses,
    double? paidFromPocket,
    double? driverCommission,
    String? driverName,
    double? driver2Commission,
    String? driver2Name,
    double? adminValue,
    double? cycleAmount,
    double? cycleDriverCommission,
    String? cycleDriverName,
    double? dayTotal,
    String? dayStatus,
    double? debtAmount,
    double? myPositionNet,
    double? partner1Debt,
    double? partner2Debt,
    double? myFinalShare,
    double? partner1FinalShare,
    double? partner2FinalShare,
    double? totalExpenses,
    double? netProfit,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return WorkRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      revenue: revenue ?? this.revenue,
      fuel: fuel ?? this.fuel,
      garage: garage ?? this.garage,
      maintenance: maintenance ?? this.maintenance,
      otherExpenses: otherExpenses ?? this.otherExpenses,
      paidFromPocket: paidFromPocket ?? this.paidFromPocket,
      driverCommission: driverCommission ?? this.driverCommission,
      driverName: driverName ?? this.driverName,
      driver2Commission: driver2Commission ?? this.driver2Commission,
      driver2Name: driver2Name ?? this.driver2Name,
      adminValue: adminValue ?? this.adminValue,
      cycleAmount: cycleAmount ?? this.cycleAmount,
      cycleDriverCommission: cycleDriverCommission ?? this.cycleDriverCommission,
      cycleDriverName: cycleDriverName ?? this.cycleDriverName,
      dayTotal: dayTotal ?? this.dayTotal,
      dayStatus: dayStatus ?? this.dayStatus,
      debtAmount: debtAmount ?? this.debtAmount,
      myPositionNet: myPositionNet ?? this.myPositionNet,
      partner1Debt: partner1Debt ?? this.partner1Debt,
      partner2Debt: partner2Debt ?? this.partner2Debt,
      myFinalShare: myFinalShare ?? this.myFinalShare,
      partner1FinalShare: partner1FinalShare ?? this.partner1FinalShare,
      partner2FinalShare: partner2FinalShare ?? this.partner2FinalShare,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date,
        'title': title,
        'revenue': revenue,
        'fuel': fuel,
        'garage': garage,
        'maintenance': maintenance,
        'other_expenses': otherExpenses,
        'paid_from_pocket': paidFromPocket,
        'driver_commission': driverCommission,
        'driver_name': driverName,
        'driver2_commission': driver2Commission,
        'driver2_name': driver2Name,
        'admin_value': adminValue,
        'cycle_amount': cycleAmount,
        'cycle_driver_commission': cycleDriverCommission,
        'cycle_driver_name': cycleDriverName,
        'day_total': dayTotal,
        'day_status': dayStatus,
        'debt_amount': debtAmount,
        'my_position_net': myPositionNet,
        'partner1_debt': partner1Debt,
        'partner2_debt': partner2Debt,
        'my_final_share': myFinalShare,
        'partner1_final_share': partner1FinalShare,
        'partner2_final_share': partner2FinalShare,
        'total_expenses': totalExpenses,
        'net_profit': netProfit,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory WorkRecord.fromMap(Map<String, Object?> map) {
    double d(String key) => ((map[key] as num?) ?? 0).toDouble();
    return WorkRecord(
      id: map['id'] as int?,
      date: map['date'] as String? ?? '',
      title: map['title'] as String? ?? '',
      revenue: d('revenue'),
      fuel: d('fuel'),
      garage: d('garage'),
      maintenance: d('maintenance'),
      otherExpenses: d('other_expenses'),
      paidFromPocket: d('paid_from_pocket'),
      driverCommission: d('driver_commission'),
      driverName: map['driver_name'] as String? ?? '',
      driver2Commission: d('driver2_commission'),
      driver2Name: map['driver2_name'] as String? ?? '',
      adminValue: d('admin_value'),
      cycleAmount: d('cycle_amount'),
      cycleDriverCommission: d('cycle_driver_commission'),
      cycleDriverName: map['cycle_driver_name'] as String? ?? '',
      dayTotal: d('day_total'),
      dayStatus: map['day_status'] as String? ?? '',
      debtAmount: d('debt_amount'),
      myPositionNet: d('my_position_net'),
      partner1Debt: d('partner1_debt'),
      partner2Debt: d('partner2_debt'),
      myFinalShare: d('my_final_share'),
      partner1FinalShare: d('partner1_final_share'),
      partner2FinalShare: d('partner2_final_share'),
      totalExpenses: d('total_expenses'),
      netProfit: d('net_profit'),
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }
}
