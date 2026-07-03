import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/work_record.dart';
import '../models/work_settings.dart';

class ReportSummary {
  final double totalRevenue;
  final double totalCycle;
  final double totalExpenses;
  final double totalAdmin;
  final double dayTotal;
  final double totalDebt;
  final double myPositionNet;
  final double myFinalShare;
  final double partner1FinalShare;
  final double partner2FinalShare;
  final int count;

  const ReportSummary({
    required this.totalRevenue,
    required this.totalCycle,
    required this.totalExpenses,
    required this.totalAdmin,
    required this.dayTotal,
    required this.totalDebt,
    required this.myPositionNet,
    required this.myFinalShare,
    required this.partner1FinalShare,
    required this.partner2FinalShare,
    required this.count,
  });

  double get netProfit => dayTotal;

  factory ReportSummary.empty() => const ReportSummary(
        totalRevenue: 0,
        totalCycle: 0,
        totalExpenses: 0,
        totalAdmin: 0,
        dayTotal: 0,
        totalDebt: 0,
        myPositionNet: 0,
        myFinalShare: 0,
        partner1FinalShare: 0,
        partner2FinalShare: 0,
        count: 0,
      );
}

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'edaret_el_shoghl.db';
  static const int _dbVersion = 2;
  static const String tableName = 'work_records';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(path, version: _dbVersion, onCreate: _createDatabase, onUpgrade: _upgradeDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        title TEXT NOT NULL,
        revenue REAL NOT NULL DEFAULT 0,
        fuel REAL NOT NULL DEFAULT 0,
        garage REAL NOT NULL DEFAULT 0,
        maintenance REAL NOT NULL DEFAULT 0,
        other_expenses REAL NOT NULL DEFAULT 0,
        paid_from_pocket REAL NOT NULL DEFAULT 0,
        driver_commission REAL NOT NULL DEFAULT 0,
        driver_name TEXT,
        driver2_commission REAL NOT NULL DEFAULT 0,
        driver2_name TEXT,
        admin_value REAL NOT NULL DEFAULT 0,
        cycle_amount REAL NOT NULL DEFAULT 0,
        cycle_driver_commission REAL NOT NULL DEFAULT 0,
        cycle_driver_name TEXT,
        day_total REAL NOT NULL DEFAULT 0,
        day_status TEXT,
        debt_amount REAL NOT NULL DEFAULT 0,
        my_position_net REAL NOT NULL DEFAULT 0,
        partner1_debt REAL NOT NULL DEFAULT 0,
        partner2_debt REAL NOT NULL DEFAULT 0,
        my_final_share REAL NOT NULL DEFAULT 0,
        partner1_final_share REAL NOT NULL DEFAULT 0,
        partner2_final_share REAL NOT NULL DEFAULT 0,
        total_expenses REAL NOT NULL DEFAULT 0,
        net_profit REAL NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_work_records_date ON $tableName(date)');
    await db.execute('CREATE INDEX idx_work_records_title ON $tableName(title)');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final existing = columns.map((c) => c['name'] as String).toSet();
    Future<void> add(String name, String type) async {
      if (!existing.contains(name)) {
        await db.execute('ALTER TABLE $tableName ADD COLUMN $name $type');
      }
    }

    await add('paid_from_pocket', 'REAL NOT NULL DEFAULT 0');
    await add('driver_commission', 'REAL NOT NULL DEFAULT 0');
    await add('driver_name', 'TEXT');
    await add('driver2_commission', 'REAL NOT NULL DEFAULT 0');
    await add('driver2_name', 'TEXT');
    await add('admin_value', 'REAL NOT NULL DEFAULT 0');
    await add('cycle_amount', 'REAL NOT NULL DEFAULT 0');
    await add('cycle_driver_commission', 'REAL NOT NULL DEFAULT 0');
    await add('cycle_driver_name', 'TEXT');
    await add('day_total', 'REAL NOT NULL DEFAULT 0');
    await add('day_status', 'TEXT');
    await add('debt_amount', 'REAL NOT NULL DEFAULT 0');
    await add('my_position_net', 'REAL NOT NULL DEFAULT 0');
    await add('partner1_debt', 'REAL NOT NULL DEFAULT 0');
    await add('partner2_debt', 'REAL NOT NULL DEFAULT 0');
    await add('my_final_share', 'REAL NOT NULL DEFAULT 0');
    await add('partner1_final_share', 'REAL NOT NULL DEFAULT 0');
    await add('partner2_final_share', 'REAL NOT NULL DEFAULT 0');
  }

  Future<WorkRecord?> getPreviousRecord(String date, {int? excludeId}) async {
    final db = await database;
    final where = excludeId == null ? 'date < ?' : 'date < ? AND id != ?';
    final args = excludeId == null ? [date] : [date, excludeId];
    final rows = await db.query(tableName, where: where, whereArgs: args, orderBy: 'date DESC, id DESC', limit: 1);
    if (rows.isEmpty) return null;
    return WorkRecord.fromMap(rows.first);
  }

  Future<int> insertRecord(WorkRecord record) async {
    final db = await database;
    return db.insert(tableName, record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertCalculatedRecord({required WorkRecord draft, required WorkSettings settings}) async {
    final previous = await getPreviousRecord(draft.date);
    final calculated = _calculateFromDraft(draft, settings, previous);
    return insertRecord(calculated);
  }

  Future<int> updateCalculatedRecord({required WorkRecord draft, required WorkSettings settings}) async {
    if (draft.id == null) return 0;
    final previous = await getPreviousRecord(draft.date, excludeId: draft.id);
    final calculated = _calculateFromDraft(draft, settings, previous).copyWith(id: draft.id);
    final db = await database;
    return db.update(tableName, calculated.toMap(), where: 'id = ?', whereArgs: [draft.id]);
  }

  WorkRecord _calculateFromDraft(WorkRecord draft, WorkSettings settings, WorkRecord? previous) {
    return WorkRecord.create(
      id: draft.id,
      date: draft.date,
      title: draft.title,
      revenue: draft.revenue,
      fuel: draft.fuel,
      garage: draft.garage,
      maintenance: draft.maintenance,
      otherExpenses: draft.otherExpenses,
      paidFromPocket: draft.paidFromPocket,
      driverCommission: draft.driverCommission,
      driverName: draft.driverName,
      driver2Commission: draft.driver2Commission,
      driver2Name: draft.driver2Name,
      cycleAmount: draft.cycleAmount,
      cycleDriverCommission: draft.cycleDriverCommission,
      cycleDriverName: draft.cycleDriverName,
      notes: draft.notes,
      settings: settings,
      previousRecord: previous,
      createdAt: draft.createdAt,
    );
  }

  Future<List<WorkRecord>> getRecords() async {
    final db = await database;
    final rows = await db.query(tableName, orderBy: 'date DESC, id DESC');
    return rows.map(WorkRecord.fromMap).toList();
  }

  Future<WorkRecord?> getRecordById(int id) async {
    final db = await database;
    final rows = await db.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return WorkRecord.fromMap(rows.first);
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAll() async {
    final db = await database;
    return db.delete(tableName);
  }

  Future<List<WorkRecord>> searchRecords(String query) async {
    final db = await database;
    final q = '%${query.trim()}%';
    final rows = await db.query(
      tableName,
      where: 'title LIKE ? OR notes LIKE ? OR date LIKE ? OR driver_name LIKE ? OR driver2_name LIKE ? OR cycle_driver_name LIKE ?',
      whereArgs: [q, q, q, q, q, q],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(WorkRecord.fromMap).toList();
  }

  Future<List<WorkRecord>> filterRecords({String? startDate, String? endDate}) async {
    final db = await database;
    String? where;
    List<Object?> args = [];
    if (startDate != null && endDate != null) {
      where = 'date BETWEEN ? AND ?';
      args = [startDate, endDate];
    } else if (startDate != null) {
      where = 'date >= ?';
      args = [startDate];
    } else if (endDate != null) {
      where = 'date <= ?';
      args = [endDate];
    }
    final rows = await db.query(tableName, where: where, whereArgs: args, orderBy: 'date DESC, id DESC');
    return rows.map(WorkRecord.fromMap).toList();
  }

  Future<ReportSummary> getSummary({String? startDate, String? endDate}) async {
    final db = await database;
    String where = '';
    List<Object?> args = [];
    if (startDate != null && endDate != null) {
      where = 'WHERE date BETWEEN ? AND ?';
      args = [startDate, endDate];
    } else if (startDate != null) {
      where = 'WHERE date >= ?';
      args = [startDate];
    } else if (endDate != null) {
      where = 'WHERE date <= ?';
      args = [endDate];
    }
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(revenue), 0) AS total_revenue,
        COALESCE(SUM(cycle_amount), 0) AS total_cycle,
        COALESCE(SUM(total_expenses), 0) AS total_expenses,
        COALESCE(SUM(admin_value), 0) AS total_admin,
        COALESCE(SUM(day_total), 0) AS day_total,
        COALESCE(SUM(debt_amount), 0) AS total_debt,
        COALESCE(SUM(my_position_net), 0) AS my_position_net,
        COALESCE(SUM(my_final_share), 0) AS my_final_share,
        COALESCE(SUM(partner1_final_share), 0) AS partner1_final_share,
        COALESCE(SUM(partner2_final_share), 0) AS partner2_final_share,
        COUNT(*) AS count
      FROM $tableName
      $where
    ''', args);
    if (rows.isEmpty) return ReportSummary.empty();
    final r = rows.first;
    double d(String k) => ((r[k] as num?) ?? 0).toDouble();
    return ReportSummary(
      totalRevenue: d('total_revenue'),
      totalCycle: d('total_cycle'),
      totalExpenses: d('total_expenses'),
      totalAdmin: d('total_admin'),
      dayTotal: d('day_total'),
      totalDebt: d('total_debt'),
      myPositionNet: d('my_position_net'),
      myFinalShare: d('my_final_share'),
      partner1FinalShare: d('partner1_final_share'),
      partner2FinalShare: d('partner2_final_share'),
      count: ((r['count'] as num?) ?? 0).toInt(),
    );
  }

  Future<WorkRecord?> getLastRecord() async {
    final db = await database;
    final rows = await db.query(tableName, orderBy: 'created_at DESC, id DESC', limit: 1);
    if (rows.isEmpty) return null;
    return WorkRecord.fromMap(rows.first);
  }

  Future<String> backupDatabase() async {
    final dbPath = await getDatabasesPath();
    final sourcePath = p.join(dbPath, _dbName);
    final dir = await getApplicationDocumentsDirectory();
    final backupPath = p.join(dir.path, 'backup_${DateTime.now().millisecondsSinceEpoch}_$_dbName');
    final source = File(sourcePath);
    if (!await source.exists()) {
      await database;
    }
    await File(sourcePath).copy(backupPath);
    return backupPath;
  }

  Future<void> restoreDatabase(String backupPath) async {
    await _database?.close();
    _database = null;
    final dbPath = await getDatabasesPath();
    final targetPath = p.join(dbPath, _dbName);
    await File(backupPath).copy(targetPath);
    _database = await _initDatabase();
  }
}
