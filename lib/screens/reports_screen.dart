import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/work_record.dart';
import '../services/export_service.dart';
import '../utils/formatters.dart';
import '../widgets/app_drawer.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_title.dart';
import '../widgets/stat_card.dart';
import '../widgets/summary_chart.dart';

class ReportsScreen extends StatefulWidget {
  static const routeName = '/reports';
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _exportService = ExportService();
  ReportSummary _summary = ReportSummary.empty();
  List<WorkRecord> _records = [];
  String _mode = 'month';
  DateTime _anchor = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _start {
    if (_mode == 'day') return Formatters.date(_anchor);
    if (_mode == 'year') return Formatters.date(DateTime(_anchor.year, 1, 1));
    return Formatters.date(DateTime(_anchor.year, _anchor.month, 1));
  }

  String get _end {
    if (_mode == 'day') return Formatters.date(_anchor);
    if (_mode == 'year') return Formatters.date(DateTime(_anchor.year, 12, 31));
    return Formatters.date(DateTime(_anchor.year, _anchor.month + 1, 0));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final summary = await DatabaseHelper.instance.getSummary(startDate: _start, endDate: _end);
    final records = await DatabaseHelper.instance.filterRecords(startDate: _start, endDate: _end);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _records = records;
      _loading = false;
    });
  }

  Future<void> _pickAnchor() async {
    final picked = await showDatePicker(context: context, initialDate: _anchor, firstDate: DateTime(2020), lastDate: DateTime(2100), locale: const Locale('ar', 'EG'));
    if (picked != null) {
      setState(() => _anchor = picked);
      _load();
    }
  }

  Future<void> _exportPdf() async {
    final file = await _exportService.exportPdf(summary: _summary, records: _records, title: 'تقرير إدارة الشغل من $_start إلى $_end');
    await _exportService.shareFile(file, text: 'تقرير PDF من تطبيق إدارة الشغل - M.R.Yassin');
  }

  Future<void> _exportExcel() async {
    final file = await _exportService.exportExcel(_records, filePrefix: 'تقرير_إدارة_الشغل');
    await _exportService.shareFile(file, text: 'تقرير Excel من تطبيق إدارة الشغل - M.R.Yassin');
  }

  Future<void> _shareSummary() async {
    final text = '''
تقرير إدارة الشغل
من $_start إلى $_end
إجمالي الإيراد: ${Formatters.money(_summary.totalRevenue)}
إجمالي المصروفات: ${Formatters.money(_summary.totalExpenses)}
إجمالي الإدارة: ${Formatters.money(_summary.totalAdmin)}
إجمالي اليوم: ${Formatters.money(_summary.dayTotal)}
نصيبي النهائي: ${Formatters.money(_summary.myFinalShare)}
شريك 1: ${Formatters.money(_summary.partner1FinalShare)}
شريك 2: ${Formatters.money(_summary.partner2FinalShare)}
عدد السجلات: ${_summary.count}
Created by M.R.Yassin
''';
    await _exportService.shareText(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'day', label: Text('يوم')),
                            ButtonSegment(value: 'month', label: Text('شهر')),
                            ButtonSegment(value: 'year', label: Text('سنة')),
                          ],
                          selected: {_mode},
                          onSelectionChanged: (v) {
                            setState(() => _mode = v.first);
                            _load();
                          },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(onPressed: _pickAnchor, icon: const Icon(Icons.calendar_month), label: Text('الفترة: $_start إلى $_end')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(context).width > 620 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.05,
                    children: [
                      StatCard(title: 'إجمالي الإيرادات', value: Formatters.money(_summary.totalRevenue), icon: Icons.trending_up, accent: Colors.greenAccent.shade400),
                      StatCard(title: 'إجمالي المصروفات', value: Formatters.money(_summary.totalExpenses), icon: Icons.payments, accent: Colors.redAccent.shade100),
                      StatCard(title: 'إجمالي الإدارة', value: Formatters.money(_summary.totalAdmin), icon: Icons.admin_panel_settings_rounded, accent: Colors.amberAccent.shade100),
                      StatCard(title: 'عدد السجلات', value: _summary.count.toString(), icon: Icons.list_alt, accent: Colors.blueAccent.shade100),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(context).width > 620 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.05,
                    children: [
                      StatCard(title: 'إجمالي اليوم', value: Formatters.money(_summary.dayTotal), icon: Icons.summarize_rounded, accent: Colors.purpleAccent.shade100),
                      StatCard(title: 'نصيبي النهائي', value: Formatters.money(_summary.myFinalShare), icon: Icons.person_rounded, accent: Colors.amberAccent.shade100),
                      StatCard(title: 'شريك 1', value: Formatters.money(_summary.partner1FinalShare), icon: Icons.group, accent: Colors.tealAccent.shade100),
                      StatCard(title: 'شريك 2', value: Formatters.money(_summary.partner2FinalShare), icon: Icons.groups, accent: Colors.cyanAccent.shade100),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle(title: 'الرسم البياني'),
                  PremiumCard(child: SummaryChart(revenue: _summary.totalRevenue, expenses: _summary.totalExpenses)),
                  const SizedBox(height: 18),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf), label: const Text('تصدير PDF ومشاركة')),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(onPressed: _exportExcel, icon: const Icon(Icons.table_view), label: const Text('تصدير Excel XLSX ومشاركة')),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(onPressed: _shareSummary, icon: const Icon(Icons.share), label: const Text('مشاركة ملخص التقرير')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
