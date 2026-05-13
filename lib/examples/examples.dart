import 'package:flutter/material.dart';

import 'budget_example.dart';
import 'datagrid_example.dart';
import 'inventory_example.dart';
import 'spreadsheet_example.dart';
import 'stress_test_example.dart';
import 'timesheet_example.dart';

/// One entry in the unified app's side-nav. New examples land here.
class ExampleEntry {
  final String label;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder build;

  /// Asset path of the .dart file backing this example. Loaded by the
  /// shell's "View source" button via `DefaultAssetBundle.loadString` so
  /// users can read and copy the exact code that drives the example.
  final String sourceAsset;

  const ExampleEntry({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.build,
    required this.sourceAsset,
  });
}

const examples = <ExampleEntry>[
  ExampleEntry(
    label: 'Budget',
    subtitle: 'Categories × months, totals, % used',
    icon: Icons.account_balance_wallet_outlined,
    build: _budget,
    sourceAsset: 'lib/examples/budget_example.dart',
  ),
  ExampleEntry(
    label: 'Timesheet',
    subtitle: 'Mark 85 — workers × cost codes',
    icon: Icons.calendar_view_week,
    build: _timesheet,
    sourceAsset: 'lib/widgets/timesheet_grid.dart',
  ),
  ExampleEntry(
    label: 'Inventory',
    subtitle: 'Minimal — 60 rows',
    icon: Icons.inventory_2_outlined,
    build: _inventory,
    sourceAsset: 'lib/examples/inventory_example.dart',
  ),
  ExampleEntry(
    label: 'Datagrid',
    subtitle: 'Search, menu, async, copy',
    icon: Icons.table_chart_outlined,
    build: _datagrid,
    sourceAsset: 'lib/examples/datagrid_example.dart',
  ),
  ExampleEntry(
    label: 'Spreadsheet',
    subtitle: 'Merged cells, totals',
    icon: Icons.grid_on_outlined,
    build: _spreadsheet,
    sourceAsset: 'lib/examples/spreadsheet_example.dart',
  ),
  ExampleEntry(
    label: 'Stress test',
    subtitle: 'Up to 5 M rows',
    icon: Icons.bolt_outlined,
    build: _stress,
    sourceAsset: 'lib/examples/stress_test_example.dart',
  ),
];

Widget _budget(BuildContext _) => const BudgetExample();
Widget _timesheet(BuildContext _) => const TimesheetExample();
Widget _inventory(BuildContext _) => const InventoryExample();
Widget _datagrid(BuildContext _) => const DatagridExample();
Widget _spreadsheet(BuildContext _) => const SpreadsheetExample();
Widget _stress(BuildContext _) => const StressTestExample();
