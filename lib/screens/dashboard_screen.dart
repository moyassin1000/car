import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../themes/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_drawer.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_title.dart';
import '../widgets/stat_card.dart';
import 'add_edit_record_screen.dart';
import 'login_screen.dart';
import 'records_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AppProvider>();
      if (!provider.isLoggedIn && mounted) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        return;
      }
      await provider.refreshDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = provider.summary;
    return Scaffold(
      appBar: AppBar(title: Text(provider.appName)),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: provider.refreshDashboard,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            PremiumCard(
              gradient: const LinearGradient(colors: [AppTheme.deepNavy, Color(0xFF111827)], begin: Alignment.topRight, end: Alignment.bottomLeft),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('لوحة إدارة الشغل', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('منطق الشيت بالكامل داخل التطبيق: الإدارة، الكمسيونات، الشركاء، والمديونية.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  const Text('Created by M.R.Yassin', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 620 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.05,
              children: [
                StatCard(title: 'إجمالي الإيرادات', value: Formatters.money(s.totalRevenue), icon: Icons.trending_up, accent: Colors.greenAccent.shade400),
                StatCard(title: 'إجمالي الإدارة', value: Formatters.money(s.totalAdmin), icon: Icons.admin_panel_settings_rounded, accent: AppTheme.gold),
                StatCard(title: 'نصيبي النهائي', value: Formatters.money(s.myFinalShare), icon: Icons.person_rounded, accent: Colors.amberAccent.shade100),
                StatCard(title: 'عدد السجلات', value: s.count.toString(), icon: Icons.list_alt_rounded, accent: Colors.blueAccent.shade100),
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
                StatCard(title: 'إجمالي المصروفات', value: Formatters.money(s.totalExpenses), icon: Icons.payments_rounded, accent: Colors.redAccent.shade100),
                StatCard(title: 'إجمالي اليوم', value: Formatters.money(s.dayTotal), icon: Icons.summarize_rounded, accent: Colors.purpleAccent.shade100),
                StatCard(title: 'شريك 1', value: Formatters.money(s.partner1FinalShare), icon: Icons.group_rounded, accent: Colors.tealAccent.shade100),
                StatCard(title: 'شريك 2', value: Formatters.money(s.partner2FinalShare), icon: Icons.groups_rounded, accent: Colors.cyanAccent.shade100),
              ],
            ),
            const SizedBox(height: 14),
            PremiumCard(
              child: Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.history_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('آخر عملية', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(provider.lastRecord == null ? 'لا توجد سجلات بعد' : '${provider.lastRecord!.date} • ${provider.lastRecord!.title} • نصيبي ${Formatters.money(provider.lastRecord!.myFinalShare)}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle(title: 'التنقل السريع'),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 620 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              children: [
                _navCard(context, Icons.add_circle, 'إضافة بيانات', AddEditRecordScreen.routeName),
                _navCard(context, Icons.table_rows, 'عرض البيانات', RecordsScreen.routeName),
                _navCard(context, Icons.analytics, 'التقارير', ReportsScreen.routeName),
                _navCard(context, Icons.settings, 'الإعدادات', SettingsScreen.routeName),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navCard(BuildContext context, IconData icon, String title, String route) {
    return PremiumCard(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.w800))]),
    );
  }
}
