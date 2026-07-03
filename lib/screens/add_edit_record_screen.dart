import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/work_record.dart';
import '../models/work_settings.dart';
import '../providers/app_provider.dart';
import '../utils/formatters.dart';
import '../widgets/app_drawer.dart';
import '../widgets/premium_card.dart';
import '../widgets/primary_button.dart';

class AddEditRecordScreen extends StatefulWidget {
  static const routeName = '/add';
  static const editRouteName = '/edit';
  final int? recordId;

  const AddEditRecordScreen({super.key, this.recordId});

  @override
  State<AddEditRecordScreen> createState() => _AddEditRecordScreenState();
}

class _AddEditRecordScreenState extends State<AddEditRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _date = TextEditingController();
  final _title = TextEditingController();
  final _revenue = TextEditingController();
  final _fuel = TextEditingController();
  final _garage = TextEditingController();
  final _maintenance = TextEditingController();
  final _other = TextEditingController();
  final _paidFromPocket = TextEditingController();
  final _driverCommission = TextEditingController();
  final _driverName = TextEditingController();
  final _driver2Commission = TextEditingController();
  final _driver2Name = TextEditingController();
  final _cycleAmount = TextEditingController();
  final _cycleDriverCommission = TextEditingController();
  final _cycleDriverName = TextEditingController();
  final _notes = TextEditingController();
  bool _loading = false;
  WorkRecord? _editing;

  bool get _isEdit => widget.recordId != null;

  @override
  void initState() {
    super.initState();
    _date.text = Formatters.date(DateTime.now());
    for (final c in _allControllers) {
      c.addListener(() => setState(() {}));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<AppProvider>().workSettings;
      if (!_isEdit && _garage.text.isEmpty) _garage.text = settings.defaultGarage.toStringAsFixed(0);
    });
    if (_isEdit) _load();
  }

  List<TextEditingController> get _allControllers => [
        _date,
        _title,
        _revenue,
        _fuel,
        _garage,
        _maintenance,
        _other,
        _paidFromPocket,
        _driverCommission,
        _driverName,
        _driver2Commission,
        _driver2Name,
        _cycleAmount,
        _cycleDriverCommission,
        _cycleDriverName,
        _notes,
      ];

  Future<void> _load() async {
    final record = await DatabaseHelper.instance.getRecordById(widget.recordId!);
    if (record == null || !mounted) return;
    _editing = record;
    _date.text = record.date;
    _title.text = record.title;
    _revenue.text = _fmt(record.revenue);
    _fuel.text = _fmt(record.fuel);
    _garage.text = _fmt(record.garage);
    _maintenance.text = _fmt(record.maintenance);
    _other.text = _fmt(record.otherExpenses);
    _paidFromPocket.text = _fmt(record.paidFromPocket);
    _driverCommission.text = _fmt(record.driverCommission);
    _driverName.text = record.driverName;
    _driver2Commission.text = _fmt(record.driver2Commission);
    _driver2Name.text = record.driver2Name;
    _cycleAmount.text = _fmt(record.cycleAmount);
    _cycleDriverCommission.text = _fmt(record.cycleDriverCommission);
    _cycleDriverName.text = record.cycleDriverName;
    _notes.text = record.notes;
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(double value) => value == 0 ? '' : value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  double _toDouble(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.').trim()) ?? 0;

  WorkRecord _draft(WorkSettings settings) {
    return WorkRecord.create(
      id: _editing?.id,
      date: _date.text,
      title: _title.text.trim().isEmpty ? 'يومية ${_date.text}' : _title.text.trim(),
      revenue: _toDouble(_revenue),
      fuel: _toDouble(_fuel),
      garage: _toDouble(_garage),
      maintenance: _toDouble(_maintenance),
      otherExpenses: _toDouble(_other),
      paidFromPocket: _toDouble(_paidFromPocket),
      driverCommission: _toDouble(_driverCommission),
      driverName: _driverName.text.trim(),
      driver2Commission: _toDouble(_driver2Commission),
      driver2Name: _driver2Name.text.trim(),
      cycleAmount: _toDouble(_cycleAmount),
      cycleDriverCommission: _toDouble(_cycleDriverCommission),
      cycleDriverName: _cycleDriverName.text.trim(),
      notes: _notes.text.trim(),
      settings: settings,
      createdAt: _editing?.createdAt,
    );
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(_date.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ar', 'EG'),
    );
    if (picked != null) _date.text = Formatters.date(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final provider = context.read<AppProvider>();
    final draft = _draft(provider.workSettings);
    if (_isEdit && _editing != null) {
      await DatabaseHelper.instance.updateCalculatedRecord(draft: draft, settings: provider.workSettings);
    } else {
      await DatabaseHelper.instance.insertCalculatedRecord(draft: draft, settings: provider.workSettings);
    }
    if (!mounted) return;
    await provider.refreshDashboard();
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEdit ? 'تم تعديل السجل بنجاح' : 'تم حفظ البيانات بنجاح')));
    if (_isEdit) {
      Navigator.pop(context, true);
    } else {
      _formKey.currentState!.reset();
      final settings = context.read<AppProvider>().workSettings;
      for (final c in _allControllers) c.clear();
      _date.text = Formatters.date(DateTime.now());
      _garage.text = settings.defaultGarage.toStringAsFixed(0);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppProvider>().workSettings;
    final preview = _draft(settings);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل السجل' : 'إضافة بيانات')),
      drawer: _isEdit ? null : const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          PremiumCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _date,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(labelText: 'التاريخ', prefixIcon: Icon(Icons.date_range_rounded)),
                    validator: (v) => (v == null || v.isEmpty) ? 'اختر التاريخ' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'اسم البيان / العملية', prefixIcon: Icon(Icons.edit_note_rounded)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب اسم البيان' : null,
                  ),
                  const SizedBox(height: 12),
                  _moneyField(_revenue, 'إيراد العربية', Icons.attach_money_rounded),
                  const SizedBox(height: 12),
                  _two(_moneyField(_fuel, 'البنزين', Icons.local_gas_station_rounded), _moneyField(_garage, 'الجراج الثابت', Icons.garage_rounded)),
                  const SizedBox(height: 12),
                  _two(_moneyField(_maintenance, 'الصيانة', Icons.build_rounded), _moneyField(_other, 'مصاريف أخرى', Icons.receipt_long_rounded)),
                  const SizedBox(height: 12),
                  _moneyField(_paidFromPocket, 'مدفوع من جيبي (مديونية)', Icons.account_balance_wallet_outlined),
                  const SizedBox(height: 12),
                  _two(_moneyField(_driverCommission, 'كمسيون السائق', Icons.payments_rounded), _driverField(_driverName, 'اسم السائق', settings)),
                  const SizedBox(height: 12),
                  _two(_moneyField(_driver2Commission, 'كمسيون سائق 2', Icons.payments_outlined), _driverField(_driver2Name, 'اسم السائق 2', settings)),
                  const SizedBox(height: 12),
                  _two(_moneyField(_cycleAmount, 'مبلغ يوم الدورة', Icons.loop_rounded), _moneyField(_cycleDriverCommission, 'كمسيون سواق الدورة', Icons.local_taxi_rounded)),
                  const SizedBox(height: 12),
                  _driverField(_cycleDriverName, 'سواق الدورة', settings),
                  const SizedBox(height: 12),
                  TextFormField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات', prefixIcon: Icon(Icons.notes_rounded))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PremiumCard(
            child: Column(
              children: [
                _calcRow('قيمة الإدارة التلقائية', Formatters.money(preview.adminValue), Icons.admin_panel_settings_rounded),
                const Divider(height: 22),
                _calcRow('إجمالي اليوم', Formatters.money(preview.dayTotal), Icons.summarize_rounded),
                const Divider(height: 22),
                _calcRow('حالة اليوم', preview.dayStatus, Icons.info_rounded),
                const Divider(height: 22),
                _calcRow('نصيبي النهائي', Formatters.money(preview.myFinalShare), Icons.person_rounded),
                const Divider(height: 22),
                _calcRow('شريك 1', Formatters.money(preview.partner1FinalShare), Icons.group_rounded),
                const Divider(height: 22),
                _calcRow('شريك 2', Formatters.money(preview.partner2FinalShare), Icons.groups_rounded),
                const SizedBox(height: 8),
                Text('ملاحظة: لو اليوم السابق كان صيانة/مصاريف بدون إيراد، الإدارة تتحسب 15% عند الحفظ.', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(text: _isEdit ? 'حفظ التعديل' : 'حفظ البيانات', icon: Icons.save_rounded, loading: _loading, onPressed: _save),
        ],
      ),
    );
  }

  Widget _two(Widget a, Widget b) => Row(children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)]);

  Widget _moneyField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)));
  }

  Widget _driverField(TextEditingController controller, String label, WorkSettings settings) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.person_pin_circle_rounded)),
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: settings.driverChoices.map((d) => ListTile(title: Text(d), onTap: () => Navigator.pop(context, d))).toList()),
          ),
        );
        if (picked != null) controller.text = picked;
      },
    );
  }

  Widget _calcRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      ],
    );
  }
}
