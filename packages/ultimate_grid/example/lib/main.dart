import 'package:flutter/material.dart';

import 'screens/async_paging_screen.dart';
import 'screens/financial_sheet_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/search_filters_screen.dart';

void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ultimate_grid example',
        theme: ThemeData(useMaterial3: true),
        home: const _Home(),
      );
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    final items = <_DemoItem>[
      _DemoItem(
        title: 'Inventory (minimal)',
        subtitle:
            'Schema + MapGridDataSource + GridController + UltimateTable.',
        icon: Icons.inventory_2_outlined,
        builder: (_) => const InventoryScreen(),
      ),
      _DemoItem(
        title: 'Financial sheet (merges + freeze)',
        subtitle:
            'Quarter header strip merged across months; top + bottom-frozen '
            'header / totals rows; left-frozen region; right-frozen TOTAL.',
        icon: Icons.calendar_view_month_outlined,
        builder: (_) => const FinancialSheetScreen(),
      ),
      _DemoItem(
        title: 'Async paging (100k rows)',
        subtitle:
            'AsyncGridDataSource fetches pages on demand with a simulated '
            'network delay. Loading placeholders flash, then become real cells.',
        icon: Icons.cloud_download_outlined,
        builder: (_) => const AsyncPagingScreen(),
      ),
      _DemoItem(
        title: 'Search & filters',
        subtitle:
            'UltimateSearchField in Highlight ↔ Filter mode + per-column '
            'filter dialogs reachable from the header menu.',
        icon: Icons.search,
        builder: (_) => const SearchFiltersScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ultimate_grid — example gallery')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final it = items[i];
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(it.icon, size: 28),
              title: Text(it.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(it.subtitle),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: it.builder,
              )),
            ),
          );
        },
      ),
    );
  }
}

class _DemoItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
  const _DemoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });
}
