import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../models/work_record.dart';
import '../models/work_settings.dart';
import '../utils/app_constants.dart';
import '../utils/formatters.dart';

class ImportResult {
  final int imported;
  final int skipped;
  final String message;

  const ImportResult({required this.imported, required this.skipped, required this.message});
}

class ExportService {
  static const dailySheet = 'سجل يومي';
  static const monthlySheet = 'ملخص شهري';

  Future<File> exportExcel(List<WorkRecord> records, {String filePrefix = 'edaret_el_shoghl'}) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', dailySheet);
    final daily = excel[dailySheet];
    daily.appendRow(_row([
      'اليوم',
      'التاريخ',
      'اسم البيان',
      'إيراد العربية',
      'البنزين',
      'الجراج الثابت',
      'الصيانة',
      'مصاريف أخرى',
      'مدفوع من جيبي (مديونية)',
      'كمسيون السائق',
      'اسم السائق',
      'كمسيون سائق 2',
      'اسم السائق 2',
      'قيمة الإدارة',
      'مبلغ يوم الدورة',
      'كمسيون سواق الدورة',
      'سواق الدورة',
      'إجمالي اليوم',
      'حالة اليوم',
      'مديونية اليوم',
      'صافي موقفي',
      'مديونية شريك 1',
      'مديونية شريك 2',
      'نصيبي النهائي',
      'نصيب شريك 1',
      'نصيب شريك 2',
      'ملاحظات',
      'تم إنشاء التقرير بواسطة M.R.Yassin',
    ]));
    for (final r in records) {
      final dt = DateTime.tryParse(r.date);
      daily.appendRow(_row([
        dt == null ? '' : DateFormat.EEEE('ar').format(dt),
        r.date,
        r.title,
        r.revenue,
        r.fuel,
        r.garage,
        r.maintenance,
        r.otherExpenses,
        r.paidFromPocket,
        r.driverCommission,
        r.driverName,
        r.driver2Commission,
        r.driver2Name,
        r.adminValue,
        r.cycleAmount,
        r.cycleDriverCommission,
        r.cycleDriverName,
        r.dayTotal,
        r.dayStatus,
        r.debtAmount,
        r.myPositionNet,
        r.partner1Debt,
        r.partner2Debt,
        r.myFinalShare,
        r.partner1FinalShare,
        r.partner2FinalShare,
        r.notes,
        'M.R.Yassin',
      ]));
    }

    final monthly = excel[monthlySheet];
    monthly.appendRow(_row(['الشهر', 'إجمالي الإيراد', 'إجمالي الدورة', 'إجمالي المصروفات', 'إجمالي الإدارة', 'إجمالي اليوم', 'مديونية اليوم', 'صافي موقفي', 'نصيبي النهائي', 'شريك 1', 'شريك 2']));
    for (var month = 1; month <= 12; month++) {
      final monthRecords = records.where((r) => (DateTime.tryParse(r.date)?.month ?? 0) == month).toList();
      monthly.appendRow(_row([
        DateFormat.MMMM('ar').format(DateTime(2026, month, 1)),
        monthRecords.fold<double>(0, (s, r) => s + r.revenue),
        monthRecords.fold<double>(0, (s, r) => s + r.cycleAmount),
        monthRecords.fold<double>(0, (s, r) => s + r.totalExpenses),
        monthRecords.fold<double>(0, (s, r) => s + r.adminValue),
        monthRecords.fold<double>(0, (s, r) => s + r.dayTotal),
        monthRecords.fold<double>(0, (s, r) => s + r.debtAmount),
        monthRecords.fold<double>(0, (s, r) => s + r.myPositionNet),
        monthRecords.fold<double>(0, (s, r) => s + r.myFinalShare),
        monthRecords.fold<double>(0, (s, r) => s + r.partner1FinalShare),
        monthRecords.fold<double>(0, (s, r) => s + r.partner2FinalShare),
      ]));
    }

    final bytes = excel.encode();
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.xlsx'));
    await file.writeAsBytes(bytes ?? <int>[]);
    return file;
  }

  Future<ImportResult> importExcelFile(File file, {required WorkSettings settings}) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[dailySheet] ?? (excel.tables.isNotEmpty ? excel.tables.values.first : null);
    if (sheet == null || sheet.rows.isEmpty) {
      return const ImportResult(imported: 0, skipped: 0, message: 'ملف Excel لا يحتوي على بيانات');
    }

    final headers = sheet.rows.first.map(_cellText).toList();
    int idx(String name, [List<String> alternatives = const []]) {
      for (var i = 0; i < headers.length; i++) {
        final h = headers[i].replaceAll(' ', '').trim();
        final n = name.replaceAll(' ', '').trim();
        if (h.contains(n)) return i;
        for (final a in alternatives) {
          if (h.contains(a.replaceAll(' ', '').trim())) return i;
        }
      }
      return -1;
    }

    final dateIdx = idx('التاريخ');
    final titleIdx = idx('اسم البيان', ['العملية', 'البيان']);
    final notesIdx = idx('ملاحظات');
    int imported = 0;
    int skipped = 0;

    for (final row in sheet.rows.skip(1)) {
      String read(int i) => i >= 0 && i < row.length ? _cellText(row[i]) : '';
      double numAt(String header, List<String> alt) => _toDouble(read(idx(header, alt)));
      final date = _normalizeDate(read(dateIdx));
      if (date.isEmpty) {
        skipped++;
        continue;
      }
      final notes = read(notesIdx);
      final title = read(titleIdx).trim().isNotEmpty ? read(titleIdx).trim() : (notes.trim().isNotEmpty ? notes.trim() : 'يومية $date');
      final now = DateTime.now().toIso8601String();
      final draft = WorkRecord.create(
        date: date,
        title: title,
        revenue: numAt('إيراد العربية', ['الإيراد']),
        fuel: numAt('البنزين', []),
        garage: numAt('الجراج الثابت', ['الجراج']),
        maintenance: numAt('الصيانة', []),
        otherExpenses: numAt('مصاريف أخرى', ['اخرى', 'أخرى']),
        paidFromPocket: numAt('مدفوع من جيبي', ['مديونية']),
        driverCommission: numAt('كمسيون السائق', []),
        driverName: read(idx('اسم السائق')).trim(),
        driver2Commission: numAt('كمسيون سائق 2', ['كمسيون سائق2']),
        driver2Name: read(idx('اسم السائق 2', ['اسم سائق 2', 'اسم سائق2'])).trim(),
        cycleAmount: numAt('مبلغ يوم الدورة', ['مبلغ الدورة']),
        cycleDriverCommission: numAt('كمسيون سواق الدورة', []),
        cycleDriverName: read(idx('سواق الدورة')).trim(),
        notes: notes,
        settings: settings,
        createdAt: now,
      );
      await DatabaseHelper.instance.insertCalculatedRecord(draft: draft, settings: settings);
      imported++;
    }

    return ImportResult(imported: imported, skipped: skipped, message: 'تم استيراد $imported سجل، وتجاهل $skipped صف');
  }

  Future<File> exportPdf({required ReportSummary summary, required List<WorkRecord> records, required String title}) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.Text('تم إنشاء التطبيق بواسطة M.R.Yassin', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pdfStat('إجمالي الإيرادات', Formatters.money(summary.totalRevenue)),
              _pdfStat('إجمالي المصروفات', Formatters.money(summary.totalExpenses)),
              _pdfStat('إجمالي الإدارة', Formatters.money(summary.totalAdmin)),
              _pdfStat('نصيبي النهائي', Formatters.money(summary.myFinalShare)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['التاريخ', 'البيان', 'الإيراد', 'الإدارة', 'إجمالي اليوم', 'نصيبي', 'شريك 1', 'شريك 2'],
            data: records
                .map((r) => [
                      r.date,
                      r.title,
                      Formatters.money(r.revenue),
                      Formatters.money(r.adminValue),
                      Formatters.money(r.dayTotal),
                      Formatters.money(r.myFinalShare),
                      Formatters.money(r.partner1FinalShare),
                      Formatters.money(r.partner2FinalShare),
                    ])
                .toList(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerRight,
            headerAlignment: pw.Alignment.centerRight,
          ),
        ],
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'report_${DateTime.now().millisecondsSinceEpoch}.pdf'));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> shareFile(File file, {String? text}) async {
    await Share.shareXFiles([XFile(file.path)], text: text);
  }

  Future<void> shareText(String text) async {
    await Share.share(text);
  }

  List<CellValue?> _row(List<Object?> values) {
    return values.map<CellValue?>((value) {
      if (value == null) return null;
      if (value is int) return IntCellValue(value);
      if (value is double) return DoubleCellValue(value);
      if (value is num) return DoubleCellValue(value.toDouble());
      return TextCellValue(value.toString());
    }).toList();
  }

  String _cellText(Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    return value.toString().trim();
  }

  double _toDouble(String text) {
    final cleaned = text.replaceAll(',', '.').replaceAll('ج.م', '').replaceAll('EGP', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  String _normalizeDate(String text) {
    final t = text.trim();
    if (t.isEmpty) return '';
    final parsed = DateTime.tryParse(t);
    if (parsed != null) return Formatters.date(parsed);
    final numeric = double.tryParse(t);
    if (numeric != null && numeric > 30000) {
      return Formatters.date(DateTime(1899, 12, 30).add(Duration(days: numeric.round())));
    }
    return t;
  }

  pw.Widget _pdfStat(String title, String value) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500), borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [pw.Text(title, style: const pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 4), pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))],
      ),
    );
  }
}
