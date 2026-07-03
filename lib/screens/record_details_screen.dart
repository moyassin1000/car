import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/work_record.dart';
import '../providers/app_provider.dart';
import '../utils/formatters.dart';
import '../widgets/premium_card.dart';
import 'add_edit_record_screen.dart';

class RecordDetailsScreen extends StatefulWidget {
  static const routeName = '/record-details';
  final int recordId;

  const RecordDetailsScreen({super.key, required this.recordId});

  @override
  State<RecordDetailsScreen> createState() => _RecordDetailsScreenState();
}

class _RecordDetailsScreenState extends State<RecordDetailsScreen> {
  WorkRecord? _record;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final record = await DatabaseHelper.instance.getRecordById(widget.recordId);
    if (!mounted) return;
    setState(() {
      _record = record;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    if (_record?.id == null) return;
    final changed = await Navigator.pushNamed(context, AddEditRecordScreen.editRouteName, arguments: _record!.id) == true;
    if (changed) _load();
  }

  Future<void> _delete() async {
    if (_record?.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا السجل؟'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف'))],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteRecord(_record!.id!);
      if (!mounted) return;
      await context.read<AppProvider>().refreshDashboard();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _record;
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل السجل')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : r == null
              ? const Center(child: Text('السجل غير موجود'))
              : ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('${r.date} • ${r.title}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          _row('إيراد العربية', r.revenue),
                          _row('البنزين', r.fuel),
                          _row('الجراج الثابت', r.garage),
                          _row('الصيانة', r.maintenance),
                          _row('مصاريف أخرى', r.otherExpenses),
                          _row('مدفوع من جيبي', r.paidFromPocket),
                          _row('كمسيون السائق', r.driverCommission, suffix: r.driverName),
                          _row('كمسيون سائق 2', r.driver2Commission, suffix: r.driver2Name),
                          _row('مبلغ يوم الدورة', r.cycleAmount),
                          _row('كمسيون سواق الدورة', r.cycleDriverCommission, suffix: r.cycleDriverName),
                          const Divider(height: 26),
                          _row('قيمة الإدارة', r.adminValue),
                          _row('إجمالي اليوم', r.dayTotal),
                          _textRow('حالة اليوم', r.dayStatus),
                          _row('مديونية اليوم', r.debtAmount),
                          _row('صافي موقفي', r.myPositionNet),
                          _row('مديونية شريك 1', r.partner1Debt),
                          _row('مديونية شريك 2', r.partner2Debt),
                          const Divider(height: 26),
                          _row('نصيبي النهائي', r.myFinalShare),
                          _row('نصيب شريك 1', r.partner1FinalShare),
                          _row('نصيب شريك 2', r.partner2FinalShare),
                          if (r.notes.isNotEmpty) ...[const Divider(height: 26), _textRow('ملاحظات', r.notes)],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton.icon(onPressed: _edit, icon: const Icon(Icons.edit), label: const Text('تعديل'))),
                        const SizedBox(width: 10),
                        Expanded(child: FilledButton.tonalIcon(onPressed: _delete, icon: const Icon(Icons.delete), label: const Text('حذف'))),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _row(String title, double value, {String? suffix}) {
    final extra = suffix == null || suffix.trim().isEmpty ? '' : ' • $suffix';
    return _textRow(title, '${Formatters.money(value)}$extra');
  }

  Widget _textRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))), const SizedBox(width: 12), Expanded(child: Text(value, textAlign: TextAlign.left))]),
    );
  }
}
