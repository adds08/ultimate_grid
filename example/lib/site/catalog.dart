import 'package:flutter/material.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

import '../screens/async_paging_screen.dart';
import '../screens/budget_screen.dart';
import '../screens/datagrid_screen.dart';
import '../screens/financial_sheet_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/office_time_log_screen.dart';
import '../screens/search_filters_screen.dart';
import '../screens/spreadsheet_screen.dart';
import '../screens/stress_test_screen.dart';

/// A single example in the showcase gallery.
///
/// Most entries are [live] — they wire a real screen widget and ship the exact
/// source the visitor can copy. [planned] entries are roadmap items (from
/// docs/STATUS.md) shown greyed-out with no live demo.
class ExampleEntry {
  /// URL slug — `/examples/<id>`.
  final String id;
  final String title;
  final IconData icon;

  /// One or two sentences shown above the live grid.
  final String description;

  /// "What this shows" bullets.
  final List<String> highlights;

  /// Builds the live widget. `null` for planned items.
  final Widget Function(GridTheme theme)? build;

  /// Asset path of the real source file shown in the CodePanel. `null` for
  /// planned items.
  final String? sourceAsset;

  /// Caption shown under the CodePanel (the real on-disk filename).
  final String? sourceLabel;

  /// Optional `// #docregion <name>` to extract from [sourceAsset].
  final String? region;

  /// `/examples/<id>` ids to surface as "See also".
  final List<String> seeAlso;

  bool get isPlanned => build == null;

  const ExampleEntry({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.highlights,
    this.build,
    this.sourceAsset,
    this.sourceLabel,
    this.region,
    this.seeAlso = const [],
  });
}

/// A named group of examples in the left nav.
class ExampleCategory {
  final String title;
  final IconData icon;
  final List<ExampleEntry> entries;
  const ExampleCategory({
    required this.title,
    required this.icon,
    required this.entries,
  });
}

const _kScreens = 'assets/source/screens';

/// The full categorized catalog driving the Examples section, the Home
/// feature-card grid, and deep links.
final exampleCategories = <ExampleCategory>[
  ExampleCategory(
    title: 'Getting Started',
    icon: Icons.rocket_launch_outlined,
    entries: [
      ExampleEntry(
        id: 'inventory',
        title: 'Inventory',
        icon: Icons.inventory_2_outlined,
        description:
            'The minimal grid: a schema, a MapGridDataSource, and a '
            'GridController feeding a single UltimateTable.',
        highlights: const [
          'Build a GridSchema with ColumnSpec / RowSpec',
          'Populate a MapGridDataSource with typed CellValues',
          'One frozen "SKU" column on the start edge',
          'Numeric column with tabular figures',
        ],
        build: (t) => InventoryScreen(theme: t),
        sourceAsset: '$_kScreens/inventory_screen.dart',
        sourceLabel: 'example/lib/screens/inventory_screen.dart',
        seeAlso: ['datagrid', 'financial-sheet'],
      ),
    ],
  ),
  ExampleCategory(
    title: 'Columns & Layout',
    icon: Icons.view_column_outlined,
    entries: [
      ExampleEntry(
        id: 'financial-sheet',
        title: 'Financial sheet',
        icon: Icons.calendar_view_month_outlined,
        description:
            'A reporting sheet that exercises cell merges and the full '
            '9-region freeze (frozen columns and frozen header/footer rows).',
        highlights: const [
          '9-region freeze: left/right columns x top/bottom rows',
          'MergeRange anchors that span multiple cells',
          'Frozen footer totals row outside the scroll body',
        ],
        build: (t) => FinancialSheetScreen(theme: t),
        sourceAsset: '$_kScreens/financial_sheet_screen.dart',
        sourceLabel: 'example/lib/screens/financial_sheet_screen.dart',
        seeAlso: ['budget', 'spreadsheet'],
      ),
      ExampleEntry(
        id: 'budget',
        title: 'Budget tracker',
        icon: Icons.account_balance_wallet_outlined,
        description:
            'Frozen leading columns with quarter header merges over a '
            'wide, horizontally-scrolling budget matrix.',
        highlights: const [
          'Frozen leading columns while the rest scrolls',
          'Merged quarter headers grouping month columns',
          'Per-column number formatting',
        ],
        build: (_) => const BudgetExample(),
        sourceAsset: '$_kScreens/budget_screen.dart',
        sourceLabel: 'example/lib/screens/budget_screen.dart',
        seeAlso: ['financial-sheet', 'spreadsheet'],
      ),
    ],
  ),
  ExampleCategory(
    title: 'Data',
    icon: Icons.storage_outlined,
    entries: [
      ExampleEntry(
        id: 'async-paging',
        title: 'Async paging',
        icon: Icons.cloud_download_outlined,
        description:
            'A 100k-row, API-backed grid using AsyncGridDataSource. Pages '
            'load on demand as you scroll, with loading placeholders.',
        highlights: const [
          'AsyncGridDataSource for paged, on-demand data',
          'Loading placeholders for not-yet-fetched rows',
          'Scales to 100k rows without preloading',
        ],
        build: (t) => AsyncPagingScreen(theme: t),
        sourceAsset: '$_kScreens/async_paging_screen.dart',
        sourceLabel: 'example/lib/screens/async_paging_screen.dart',
        seeAlso: ['stress-test', 'inventory'],
      ),
    ],
  ),
  ExampleCategory(
    title: 'Sort / Filter / Search',
    icon: Icons.filter_alt_outlined,
    entries: [
      ExampleEntry(
        id: 'search-filters',
        title: 'Search & filters',
        icon: Icons.search,
        description:
            'The UltimateSearchField in Highlight and Filter modes, plus the '
            'per-column header menu with type-aware filter dialogs.',
        highlights: const [
          'UltimateSearchField: Highlight vs Filter modes',
          'Column header menu: sort, pin, hide, fit, filter',
          'Filters.* pre-built predicates by cell type',
          'Single-pass ViewPipeline (filter -> sort -> search)',
        ],
        build: (t) => SearchFiltersScreen(theme: t),
        sourceAsset: '$_kScreens/search_filters_screen.dart',
        sourceLabel: 'example/lib/screens/search_filters_screen.dart',
        seeAlso: ['datagrid', 'inventory'],
      ),
    ],
  ),
  ExampleCategory(
    title: 'Interaction',
    icon: Icons.ads_click_outlined,
    entries: [
      ExampleEntry(
        id: 'datagrid',
        title: 'Datagrid',
        icon: Icons.table_rows_outlined,
        description:
            '200 rows with sorting, filtering, column pinning, drag-resize '
            'and drag-reorder — the interactive data-table feature set.',
        highlights: const [
          'Excel-style rectangle selection + TSV clipboard copy',
          'Sort / filter / pin from the column header menu',
          'Drag-to-resize and drag-to-reorder columns',
        ],
        build: (_) => const DatagridExample(),
        sourceAsset: '$_kScreens/datagrid_screen.dart',
        sourceLabel: 'example/lib/screens/datagrid_screen.dart',
        seeAlso: ['search-filters', 'spreadsheet'],
      ),
    ],
  ),
  ExampleCategory(
    title: 'Real-world demos',
    icon: Icons.workspaces_outline,
    entries: [
      ExampleEntry(
        id: 'office-time-log',
        title: 'Office Time Log',
        icon: Icons.access_time_outlined,
        description:
            'Engineers x sub-tasks timesheet reframed for IT projects — the '
            'demo that motivated the package. Widget cells, totals, merges.',
        highlights: const [
          'Interactive widget cells (widgetColumns + cellWidgetBuilder)',
          'Derived totals that track edits',
          'Header merges grouping sub-tasks under projects',
        ],
        build: (t) => OfficeTimeLogScreen(theme: t),
        sourceAsset: '$_kScreens/office_time_log_screen.dart',
        sourceLabel: 'example/lib/screens/office_time_log_screen.dart',
        seeAlso: ['budget', 'spreadsheet'],
      ),
      ExampleEntry(
        id: 'spreadsheet',
        title: 'Spreadsheet',
        icon: Icons.grid_on_outlined,
        description:
            'A matrix-style table with merged headers and in-cell editing — '
            'the closest analog to a classic spreadsheet surface.',
        highlights: const [
          'In-cell editor (double-tap; Enter commits, Esc cancels)',
          'Merged headers across a matrix layout',
          'Keyboard navigation between cells',
        ],
        build: (_) => const SpreadsheetExample(),
        sourceAsset: '$_kScreens/spreadsheet_screen.dart',
        sourceLabel: 'example/lib/screens/spreadsheet_screen.dart',
        seeAlso: ['datagrid', 'office-time-log'],
      ),
    ],
  ),
  ExampleCategory(
    title: 'Performance',
    icon: Icons.speed_outlined,
    entries: [
      ExampleEntry(
        id: 'stress-test',
        title: 'Stress test',
        icon: Icons.bolt_outlined,
        description:
            'Up to 5 million rows on the custom-paint body. Only the visible '
            'window paints each frame — no widget tree per cell.',
        highlights: const [
          'RenderUltimateBody canvas paint with ParagraphCache LRU',
          'Row-count slider up to ~5M rows',
          'Constant memory: only the visible window paints',
        ],
        build: (_) => const StressTestExample(),
        sourceAsset: '$_kScreens/stress_test_screen.dart',
        sourceLabel: 'example/lib/screens/stress_test_screen.dart',
        seeAlso: ['async-paging'],
      ),
    ],
  ),
  ExampleCategory(
    title: 'Planned',
    icon: Icons.event_outlined,
    entries: [
      ExampleEntry(
        id: 'planned-csv-export',
        title: 'CSV / Excel export',
        icon: Icons.download_outlined,
        description: 'Export the current view or selection to CSV / .xlsx.',
        highlights: const ['Planned — see the Roadmap for status.'],
      ),
      ExampleEntry(
        id: 'planned-pagination',
        title: 'Pagination widget',
        icon: Icons.last_page_outlined,
        description:
            'Page-size control + pager UI as an alternative to infinite '
            'scroll.',
        highlights: const ['Planned — see the Roadmap for status.'],
      ),
      ExampleEntry(
        id: 'planned-row-grouping',
        title: 'Row grouping / tree rows',
        icon: Icons.account_tree_outlined,
        description: 'Collapsible groups with aggregate header rows.',
        highlights: const ['Planned — see the Roadmap for status.'],
      ),
      ExampleEntry(
        id: 'planned-frozen-totals',
        title: 'Frozen totals',
        icon: Icons.functions_outlined,
        description:
            'Declarative sum/avg footer rows that track the filtered view.',
        highlights: const ['Planned — see the Roadmap for status.'],
      ),
      ExampleEntry(
        id: 'planned-rtl',
        title: 'RTL support',
        icon: Icons.format_textdirection_r_to_l_outlined,
        description: 'Mirror freeze regions and alignment for RTL locales.',
        highlights: const ['Planned — see the Roadmap for status.'],
      ),
      ExampleEntry(
        id: 'planned-a11y',
        title: 'Accessibility',
        icon: Icons.accessibility_new_outlined,
        description: 'Semantics nodes for the painted body (screen readers).',
        highlights: const ['Planned — see the Roadmap for status.'],
      ),
    ],
  ),
];

/// Flat list of every entry (for lookup by id).
final allExamples = <ExampleEntry>[
  for (final c in exampleCategories) ...c.entries,
];

/// Live examples only (used for the Home feature-card grid).
final liveExamples = allExamples.where((e) => !e.isPlanned).toList();

ExampleEntry? exampleById(String id) {
  for (final e in allExamples) {
    if (e.id == id) return e;
  }
  return null;
}

ExampleCategory categoryOf(ExampleEntry entry) {
  return exampleCategories.firstWhere((c) => c.entries.contains(entry));
}
