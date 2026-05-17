import 'package:flutter/material.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

import 'shared.dart';

/// Personal monthly budget tracker — a relatable, fairly complex example
/// exercising:
///   - Frozen-left columns (category + budget amount)
///   - 12 scrollable month columns
///   - Frozen-right columns (year-to-date total + % of budget used)
///   - A two-row frozen header strip with **merged-cell quarter labels**
///     (Q1 / Q2 / Q3 / Q4 each span 3 month columns via `MergeRange`)
///   - A frozen-bottom totals row
///   - Widget-overlay cells for the category column (icon + label) and the
///     % used column (progress bar with conditional colour)
///   - Editable monthly amounts (double-tap a cell, type, Enter)
///   - Per-cell colour via the `_overspendOverlay` painted-on tint when a
///     month's spend exceeds `budget / 12`
class BudgetExample extends StatefulWidget {
  const BudgetExample({super.key});

  @override
  State<BudgetExample> createState() => _BudgetExampleState();
}

class _BudgetExampleState extends State<BudgetExample> {
  static const _categoryColId = 'category';
  static const _budgetColId = 'budget';
  static const _totalColId = 'total';
  static const _percentColId = 'percent';

  static const _quarterRowId = '__quarter';
  static const _headerRowId = '__header';
  static const _totalsRowId = '__totals';

  static const _months = <String>[
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  ];

  late final List<_Category> _categories;
  late final MapGridDataSource _source;
  late final GridSchema _schema;
  late GridController _controller;

  @override
  void initState() {
    super.initState();
    _categories = _seedCategories();
    _schema = _buildSchema();
    _source = MapGridDataSource(
      rowIds: [
        _quarterRowId,
        _headerRowId,
        ..._categories.map((c) => c.id),
        _totalsRowId,
      ],
      colIds: [
        _categoryColId,
        _budgetColId,
        ..._months,
        _totalColId,
        _percentColId,
      ],
    );
    _seedData();
    _addQuarterMerges();
    _controller = GridController(schema: _schema, source: _source);
    _source.addListener(_recomputeDerived);
  }

  @override
  void dispose() {
    _source.removeListener(_recomputeDerived);
    _controller.dispose();
    _source.dispose();
    super.dispose();
  }

  GridSchema _buildSchema() {
    return GridSchema(
      columns: [
        const ColumnSpec(
          id: _categoryColId,
          header: 'Category',
          defaultWidth: 200,
          defaultFrozen: FrozenSide.start,
          defaultFreezePriority: 0,
          kind: CellKind.text,
          sortable: false,
        ),
        const ColumnSpec(
          id: _budgetColId,
          header: 'Budget',
          defaultWidth: 110,
          defaultFrozen: FrozenSide.start,
          defaultFreezePriority: 1,
          kind: CellKind.number,
        ),
        for (final m in _months)
          ColumnSpec(
            id: m,
            header: m.toUpperCase(),
            defaultWidth: 80,
            kind: CellKind.number,
          ),
        const ColumnSpec(
          id: _totalColId,
          header: 'YTD',
          defaultWidth: 110,
          defaultFrozen: FrozenSide.end,
          defaultFreezePriority: 1,
          kind: CellKind.number,
        ),
        const ColumnSpec(
          id: _percentColId,
          header: '% used',
          defaultWidth: 120,
          defaultFrozen: FrozenSide.end,
          defaultFreezePriority: 0,
          kind: CellKind.text,
          sortable: false,
        ),
      ],
      rows: [
        const RowSpec(
          id: _quarterRowId,
          defaultHeight: 32,
          defaultFrozen: FrozenSide.start,
          defaultFreezePriority: 0,
        ),
        const RowSpec(
          id: _headerRowId,
          defaultHeight: 36,
          defaultFrozen: FrozenSide.start,
          defaultFreezePriority: 1,
        ),
        for (final c in _categories) RowSpec(id: c.id, defaultHeight: 44),
        const RowSpec(
          id: _totalsRowId,
          defaultHeight: 44,
          defaultFrozen: FrozenSide.end,
        ),
      ],
    );
  }

  void _addQuarterMerges() {
    for (var q = 0; q < 4; q++) {
      _source.addMerge(MergeRange(
        anchorRow: _quarterRowId,
        anchorCol: _months[q * 3],
        rowSpan: 1,
        colSpan: 3,
      ));
    }
  }

  void _seedData() {
    // Quarter row labels (one anchor per merge).
    const quarters = ['Q1', 'Q2', 'Q3', 'Q4'];
    for (var q = 0; q < 4; q++) {
      _source.setValue(_quarterRowId, _months[q * 3], TextCell(quarters[q]));
    }
    // Header row labels per month — these duplicate the column header but
    // sit in the frozen row strip so they scroll horizontally with the
    // body. Column headers above are rendered by `headerBuilder`.
    for (final m in _months) {
      _source.setValue(_headerRowId, m, TextCell(m.toUpperCase()));
    }

    // Category rows.
    for (final c in _categories) {
      _source.setValue(c.id, _categoryColId, TextCell(c.name));
      _source.setValue(c.id, _budgetColId, NumberCell(c.budget));
      for (var i = 0; i < _months.length; i++) {
        _source.setValue(c.id, _months[i], NumberCell(c.monthly[i]));
      }
    }
    _recomputeDerived();
  }

  /// Derived totals (YTD, % used, monthly totals). Runs whenever the
  /// source mutates — wired via `source.addListener` in initState.
  void _recomputeDerived() {
    if (!mounted) return;
    // Per-category totals + % used.
    for (final c in _categories) {
      var spent = 0.0;
      for (final m in _months) {
        final v = _source.valueAt(c.id, m);
        if (v is NumberCell) spent += v.value;
      }
      final budgetCell = _source.valueAt(c.id, _budgetColId);
      final budget = budgetCell is NumberCell ? budgetCell.value : 0.0;
      _source.setValue(c.id, _totalColId, NumberCell(_round(spent)));
      _source.setValue(c.id, _percentColId,
          NumberCell(budget == 0 ? 0 : _round((spent / budget) * 100)));
    }
    // Monthly column totals + grand totals.
    var grandSpend = 0.0;
    var grandBudget = 0.0;
    for (final c in _categories) {
      grandBudget += c.budget;
    }
    _source.setValue(_totalsRowId, _categoryColId, const TextCell('TOTAL'));
    _source.setValue(_totalsRowId, _budgetColId, NumberCell(_round(grandBudget)));
    for (final m in _months) {
      var monthTotal = 0.0;
      for (final c in _categories) {
        final v = _source.valueAt(c.id, m);
        if (v is NumberCell) monthTotal += v.value;
      }
      _source.setValue(_totalsRowId, m, NumberCell(_round(monthTotal)));
      grandSpend += monthTotal;
    }
    _source.setValue(_totalsRowId, _totalColId, NumberCell(_round(grandSpend)));
    _source.setValue(_totalsRowId, _percentColId,
        NumberCell(_round(grandBudget == 0 ? 0 : (grandSpend / grandBudget) * 100)));
  }

  static double _round(double v) => double.parse(v.toStringAsFixed(2));

  void _onCommit(RowId rowId, ColId colId, CellValue value) {
    // Block edits on synthetic rows + derived columns.
    if (rowId == _quarterRowId ||
        rowId == _headerRowId ||
        rowId == _totalsRowId) {
      return;
    }
    if (colId == _categoryColId ||
        colId == _totalColId ||
        colId == _percentColId) {
      return;
    }
    _source.setValue(rowId, colId, value);
  }

  Widget _cellWidget(BuildContext ctx, RowId rowId, ColId colId,
      CellValue value) {
    if (colId == _categoryColId) {
      return _CategoryCell(rowId: rowId, categories: _categories,
          isHeader: rowId == _quarterRowId || rowId == _headerRowId,
          isTotals: rowId == _totalsRowId);
    }
    if (colId == _percentColId) {
      if (rowId == _quarterRowId || rowId == _headerRowId) {
        return const SizedBox.shrink();
      }
      final pct = value is NumberCell ? value.value : 0.0;
      return _PercentBar(percent: pct);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HelpBanner(
            text:
                'Monthly budget tracker. Frozen-left = category + budget. '
                'Frozen-right = YTD spend + % used (progress bar widget). '
                'Frozen-top = quarter labels (merged across 3 months) + '
                'month header. Frozen-bottom = totals. Double-tap any '
                'monthly cell to edit — totals + % update on commit.',
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: UltimateTable(
                controller: _controller,
                headerBuilder: (ctx, colId) => HeaderLabel(
                    controller: _controller, colId: colId),
                widgetColumns: const {_categoryColId, _percentColId},
                cellWidgetBuilder: _cellWidget,
                onCellCommit: _onCommit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<_Category> _seedCategories() {
    return const [
      _Category(
        id: 'rent',
        name: 'Rent / Mortgage',
        icon: Icons.home_outlined,
        color: Color(0xFFEFF6FF),
        budget: 1600,
        monthly: [1600, 1600, 1600, 1600, 1600, 1600, 1600, 1600, 1600, 1600, 1600, 1600],
      ),
      _Category(
        id: 'utilities',
        name: 'Utilities',
        icon: Icons.bolt_outlined,
        color: Color(0xFFFEF3C7),
        budget: 1800,
        monthly: [180, 175, 160, 140, 110, 90, 95, 100, 130, 150, 165, 175],
      ),
      _Category(
        id: 'groceries',
        name: 'Groceries',
        icon: Icons.shopping_basket_outlined,
        color: Color(0xFFDCFCE7),
        budget: 4800,
        monthly: [410, 390, 405, 420, 445, 460, 470, 455, 415, 400, 425, 440],
      ),
      _Category(
        id: 'dining',
        name: 'Dining out',
        icon: Icons.restaurant_outlined,
        color: Color(0xFFFFEDD5),
        budget: 1200,
        monthly: [85, 110, 95, 120, 140, 160, 175, 140, 105, 90, 95, 130],
      ),
      _Category(
        id: 'transport',
        name: 'Transport',
        icon: Icons.directions_car_outlined,
        color: Color(0xFFEDE9FE),
        budget: 1800,
        monthly: [140, 130, 150, 175, 160, 145, 165, 180, 170, 155, 135, 150],
      ),
      _Category(
        id: 'insurance',
        name: 'Insurance',
        icon: Icons.shield_outlined,
        color: Color(0xFFE0E7FF),
        budget: 1440,
        monthly: [120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120],
      ),
      _Category(
        id: 'subscriptions',
        name: 'Subscriptions',
        icon: Icons.subscriptions_outlined,
        color: Color(0xFFFCE7F3),
        budget: 720,
        monthly: [62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62],
      ),
      _Category(
        id: 'health',
        name: 'Health & fitness',
        icon: Icons.favorite_outline,
        color: Color(0xFFFEE2E2),
        budget: 960,
        monthly: [80, 75, 85, 80, 90, 100, 95, 85, 80, 80, 75, 85],
      ),
      _Category(
        id: 'entertainment',
        name: 'Entertainment',
        icon: Icons.theaters_outlined,
        color: Color(0xFFFFE4E6),
        budget: 600,
        monthly: [55, 40, 60, 50, 70, 80, 90, 75, 55, 45, 50, 60],
      ),
      _Category(
        id: 'travel',
        name: 'Travel',
        icon: Icons.flight_takeoff_outlined,
        color: Color(0xFFCFFAFE),
        budget: 2400,
        monthly: [0, 0, 0, 850, 0, 0, 1400, 200, 0, 0, 0, 350],
      ),
      _Category(
        id: 'shopping',
        name: 'Shopping',
        icon: Icons.shopping_bag_outlined,
        color: Color(0xFFF5D0FE),
        budget: 1500,
        monthly: [60, 110, 95, 130, 80, 120, 140, 110, 100, 90, 200, 380],
      ),
      _Category(
        id: 'gifts',
        name: 'Gifts',
        icon: Icons.card_giftcard_outlined,
        color: Color(0xFFFEF9C3),
        budget: 800,
        monthly: [40, 60, 30, 50, 80, 40, 30, 20, 50, 80, 110, 220],
      ),
      _Category(
        id: 'savings',
        name: 'Savings',
        icon: Icons.savings_outlined,
        color: Color(0xFFD1FAE5),
        budget: 6000,
        monthly: [500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500],
      ),
      _Category(
        id: 'misc',
        name: 'Miscellaneous',
        icon: Icons.more_horiz_outlined,
        color: Color(0xFFE2E8F0),
        budget: 600,
        monthly: [50, 30, 70, 25, 45, 60, 40, 80, 50, 35, 90, 60],
      ),
    ];
  }
}

class _Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double budget;
  final List<double> monthly;
  const _Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.budget,
    required this.monthly,
  });
}

class _CategoryCell extends StatelessWidget {
  final RowId rowId;
  final List<_Category> categories;
  final bool isHeader;
  final bool isTotals;
  const _CategoryCell({
    required this.rowId,
    required this.categories,
    required this.isHeader,
    required this.isTotals,
  });

  @override
  Widget build(BuildContext context) {
    if (isHeader) {
      return Container(
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: const Text(
          'CATEGORY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
      );
    }
    if (isTotals) {
      return Container(
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: const Text(
          'TOTAL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    final cat = categories.firstWhere((c) => c.id == rowId,
        orElse: () => const _Category(
              id: '', name: '?', icon: Icons.help_outline,
              color: Color(0xFFE2E8F0), budget: 0, monthly: [],
            ));
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: cat.color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(cat.icon, size: 16, color: const Color(0xFF334155)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cat.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentBar extends StatelessWidget {
  final double percent;
  const _PercentBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 130.0);
    final over = percent > 100;
    final color = over
        ? const Color(0xFFDC2626)
        : (percent > 85
            ? const Color(0xFFEA580C)
            : const Color(0xFF16A34A));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (over)
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: Color(0xFFDC2626)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: clamped / 100.0,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
