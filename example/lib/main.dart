import 'package:flutter/material.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

import 'screens/_themes.dart';
import 'screens/async_paging_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/datagrid_screen.dart';
import 'screens/financial_sheet_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/office_time_log_screen.dart';
import 'screens/search_filters_screen.dart';
import 'screens/spreadsheet_screen.dart';
import 'screens/stress_test_screen.dart';

void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ultimate_grid example',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const _Shell(),
      );
}

class _ExampleEntry {
  final String label;
  final String subtitle;
  final IconData icon;
  final Widget Function(GridTheme theme) build;
  const _ExampleEntry({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.build,
  });
}

final _examples = <_ExampleEntry>[
  _ExampleEntry(
    label: 'Inventory',
    subtitle: 'Minimal — 60 rows',
    icon: Icons.inventory_2_outlined,
    build: (t) => InventoryScreen(theme: t),
  ),
  _ExampleEntry(
    label: 'Financial sheet',
    subtitle: 'Merges + 9-region freeze',
    icon: Icons.calendar_view_month_outlined,
    build: (t) => FinancialSheetScreen(theme: t),
  ),
  _ExampleEntry(
    label: 'Async paging',
    subtitle: '100k rows, on-demand',
    icon: Icons.cloud_download_outlined,
    build: (t) => AsyncPagingScreen(theme: t),
  ),
  _ExampleEntry(
    label: 'Search & filters',
    subtitle: 'Highlight / filter + per-column',
    icon: Icons.search,
    build: (t) => SearchFiltersScreen(theme: t),
  ),
  _ExampleEntry(
    label: 'Office Time Log',
    subtitle: 'Engineers × sub-tasks, IT framing',
    icon: Icons.access_time_outlined,
    build: (t) => OfficeTimeLogScreen(theme: t),
  ),
  _ExampleEntry(
    label: 'Budget tracker',
    subtitle: 'Frozen cols + quarter merges',
    icon: Icons.account_balance_wallet_outlined,
    build: (_) => const BudgetExample(),
  ),
  _ExampleEntry(
    label: 'Datagrid',
    subtitle: '200 rows, sort / filter / pin',
    icon: Icons.table_rows_outlined,
    build: (_) => const DatagridExample(),
  ),
  _ExampleEntry(
    label: 'Spreadsheet',
    subtitle: 'Matrix table + merged headers',
    icon: Icons.grid_on_outlined,
    build: (_) => const SpreadsheetExample(),
  ),
  _ExampleEntry(
    label: 'Stress test',
    subtitle: 'Up to 5 M rows, canvas-paint',
    icon: Icons.speed_outlined,
    build: (_) => const StressTestExample(),
  ),
];

class _Shell extends StatefulWidget {
  const _Shell();
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _selected = 0;
  DemoTheme _themeName = DemoTheme.elegant;
  Color? _accent;
  bool _sidebarCollapsed = false;
  bool _mobilePreview = false;

  static const _mobileMaxWidth = 380.0;

  GridTheme get _theme => themeFor(_themeName, accent: _accent);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = _mobilePreview || width < 760;
    final example = _examples[_selected];

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          example: example,
          themeName: _themeName,
          accent: _accent,
          compact: compact,
          mobilePreview: _mobilePreview,
          onThemeChanged: (t) => setState(() => _themeName = t),
          onAccentChanged: (c) => setState(() => _accent = c),
          onToggleMobile: () =>
              setState(() => _mobilePreview = !_mobilePreview),
          onOpenMenu: compact
              ? () => Scaffold.of(_scaffoldContext!).openDrawer()
              : null,
        ),
        Expanded(
          child: KeyedSubtree(
            // Re-key on theme change so each screen rebuilds its
            // internal table with the new theme.
            key: ValueKey('$_selected:${_themeName.name}:${_accent?.toARGB32()}'),
            child: example.build(_theme),
          ),
        ),
      ],
    );

    final mobileFramed = _mobilePreview
        ? Center(
            child: Container(
              width: _mobileMaxWidth,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: body,
            ),
          )
        : body;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: compact
          ? Drawer(
              child: SafeArea(
                child: _SidebarList(
                  selected: _selected,
                  collapsed: false,
                  onSelect: (i) {
                    setState(() => _selected = i);
                    Navigator.of(context).maybePop();
                  },
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Builder(builder: (ctx) {
          _scaffoldContext = ctx;
          return compact
              ? mobileFramed
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Sidebar(
                      selected: _selected,
                      collapsed: _sidebarCollapsed,
                      onSelect: (i) => setState(() => _selected = i),
                      onToggleCollapsed: () => setState(
                          () => _sidebarCollapsed = !_sidebarCollapsed),
                    ),
                    const VerticalDivider(
                        width: 1, color: Color(0xFFE2E8F0)),
                    Expanded(child: mobileFramed),
                  ],
                );
        }),
      ),
    );
  }

  BuildContext? _scaffoldContext;
}

class _Sidebar extends StatelessWidget {
  final int selected;
  final bool collapsed;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggleCollapsed;
  const _Sidebar({
    required this.selected,
    required this.collapsed,
    required this.onSelect,
    required this.onToggleCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: collapsed ? 60 : 240,
      color: const Color(0xFFFFFBF5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarHeader(
            collapsed: collapsed,
            onToggleCollapsed: onToggleCollapsed,
          ),
          Expanded(
            child: _SidebarList(
              selected: selected,
              collapsed: collapsed,
              onSelect: onSelect,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  const _SidebarHeader({
    required this.collapsed,
    required this.onToggleCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: collapsed
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 14)
          : const EdgeInsets.fromLTRB(16, 18, 8, 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFEA580C),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.grid_view_rounded,
                size: 16, color: Colors.white),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ultimate Grid',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'by CodeBigya · examples',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFC2410C),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            onPressed: onToggleCollapsed,
            icon: Icon(
              collapsed ? Icons.menu_open : Icons.menu,
              size: 18,
              color: const Color(0xFF64748B),
            ),
            tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SidebarList extends StatelessWidget {
  final int selected;
  final bool collapsed;
  final ValueChanged<int> onSelect;
  const _SidebarList({
    required this.selected,
    required this.collapsed,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: _examples.length,
      itemBuilder: (ctx, i) {
        final e = _examples[i];
        final active = i == selected;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Material(
            color: active ? const Color(0xFFFFF7ED) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelect(i),
              child: Tooltip(
                message: collapsed ? e.label : '',
                child: Padding(
                  padding: collapsed
                      ? const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10)
                      : const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                  child: collapsed
                      ? Center(
                          child: Icon(
                            e.icon,
                            size: 20,
                            color: active
                                ? const Color(0xFFEA580C)
                                : const Color(0xFF64748B),
                          ),
                        )
                      : Row(
                          children: [
                            Icon(
                              e.icon,
                              size: 18,
                              color: active
                                  ? const Color(0xFFEA580C)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: active
                                          ? const Color(0xFFEA580C)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    e.subtitle,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final _ExampleEntry example;
  final DemoTheme themeName;
  final Color? accent;
  final bool compact;
  final bool mobilePreview;
  final ValueChanged<DemoTheme> onThemeChanged;
  final ValueChanged<Color?> onAccentChanged;
  final VoidCallback onToggleMobile;
  final VoidCallback? onOpenMenu;
  const _TopBar({
    required this.example,
    required this.themeName,
    required this.accent,
    required this.compact,
    required this.mobilePreview,
    required this.onThemeChanged,
    required this.onAccentChanged,
    required this.onToggleMobile,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (onOpenMenu != null) ...[
            IconButton(
              onPressed: onOpenMenu,
              icon: const Icon(Icons.menu, size: 20),
              visualDensity: VisualDensity.compact,
              tooltip: 'Examples',
            ),
            const SizedBox(width: 4),
          ],
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(example.icon,
                size: 16, color: const Color(0xFFEA580C)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  example.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ThemePicker(
            themeName: themeName,
            accent: accent,
            onThemeChanged: onThemeChanged,
            onAccentChanged: onAccentChanged,
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onToggleMobile,
            icon: Icon(
              mobilePreview
                  ? Icons.desktop_windows_outlined
                  : Icons.smartphone_outlined,
              size: 18,
            ),
            tooltip: mobilePreview
                ? 'Exit mobile preview'
                : 'Preview as mobile',
            visualDensity: VisualDensity.compact,
            color: mobilePreview ? const Color(0xFFEA580C) : null,
          ),
        ],
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  final DemoTheme themeName;
  final Color? accent;
  final ValueChanged<DemoTheme> onThemeChanged;
  final ValueChanged<Color?> onAccentChanged;
  const _ThemePicker({
    required this.themeName,
    required this.accent,
    required this.onThemeChanged,
    required this.onAccentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        DropdownButton<DemoTheme>(
          value: themeName,
          isDense: true,
          underline: const SizedBox.shrink(),
          icon: const Icon(Icons.expand_more, size: 16),
          items: const [
            DropdownMenuItem(value: DemoTheme.raw, child: Text('Raw')),
            DropdownMenuItem(
                value: DemoTheme.elegant, child: Text('Elegant')),
            DropdownMenuItem(
                value: DemoTheme.professional, child: Text('Professional')),
          ],
          onChanged: (v) {
            if (v != null) onThemeChanged(v);
          },
        ),
        for (final s in accentSwatches)
          _AccentDot(
            color: s.color,
            label: s.label,
            selected: accent?.toARGB32() == s.color.toARGB32(),
            onTap: () => onAccentChanged(
              accent?.toARGB32() == s.color.toARGB32() ? null : s.color,
            ),
          ),
      ],
    );
  }
}

class _AccentDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AccentDot({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: selected ? '$label (clear)' : label,
      child: InkResponse(
        onTap: onTap,
        radius: 14,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFE2E8F0),
                width: selected ? 2 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
