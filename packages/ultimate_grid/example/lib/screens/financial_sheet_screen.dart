import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

import '_shared.dart';

class FinancialSheetScreen extends StatefulWidget {
  const FinancialSheetScreen({super.key});

  @override
  State<FinancialSheetScreen> createState() => _FinancialSheetScreenState();
}

class _FinancialSheetScreenState extends State<FinancialSheetScreen> {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _quarters = ['Q1', 'Q2', 'Q3', 'Q4'];
  static const _regions = ['North', 'South', 'East', 'West', 'Central'];
  static const _quarterRowId = '__quarter';
  static const _monthRowId = '__month';
  static const _totalsRowId = '__totals';

  late final MapGridDataSource _source;
  late final GridController _controller;

  @override
  void initState() {
    super.initState();
    final schema = GridSchema(
      columns: [
        const ColumnSpec(
          id: 'region',
          header: 'REGION',
          defaultWidth: 130,
          defaultFrozen: FrozenSide.start,
        ),
        for (final m in _months)
          ColumnSpec(
            id: m.toLowerCase(),
            header: m.toUpperCase(),
            defaultWidth: 90,
            kind: CellKind.number,
          ),
        const ColumnSpec(
          id: 'total',
          header: 'TOTAL',
          defaultWidth: 110,
          kind: CellKind.number,
          defaultFrozen: FrozenSide.end,
        ),
      ],
      rows: [
        const RowSpec(
          id: _quarterRowId,
          defaultHeight: 36,
          defaultFrozen: FrozenSide.start,
          defaultFreezePriority: 0,
        ),
        const RowSpec(
          id: _monthRowId,
          defaultHeight: 36,
          defaultFrozen: FrozenSide.start,
          defaultFreezePriority: 1,
        ),
        for (final r in _regions) RowSpec(id: r, defaultHeight: 44),
        const RowSpec(
          id: _totalsRowId,
          defaultHeight: 44,
          defaultFrozen: FrozenSide.end,
        ),
      ],
    );
    _source = MapGridDataSource(
      rowIds: [_quarterRowId, _monthRowId, ..._regions, _totalsRowId],
      colIds: ['region', ..._months.map((m) => m.toLowerCase()), 'total'],
    );
    _seed();
    _addMerges();
    _controller = GridController(schema: schema, source: _source);
  }

  void _seed() {
    final rng = math.Random(7);
    for (var q = 0; q < 4; q++) {
      _source.setValue(_quarterRowId, _months[q * 3].toLowerCase(),
          TextCell(_quarters[q]));
    }
    final perCol = <String, double>{};
    for (final r in _regions) {
      _source.setValue(r, 'region', TextCell(r));
      var rowTotal = 0.0;
      for (final m in _months) {
        final v = rng.nextDouble() * 90 + 10;
        _source.setValue(
            r, m.toLowerCase(), NumberCell(double.parse(v.toStringAsFixed(1))));
        perCol[m.toLowerCase()] = (perCol[m.toLowerCase()] ?? 0) + v;
        rowTotal += v;
      }
      _source.setValue(
          r, 'total', NumberCell(double.parse(rowTotal.toStringAsFixed(1))));
    }
    _source.setValue(_totalsRowId, 'region', const TextCell('TOTAL'));
    var grand = 0.0;
    for (final m in _months) {
      final t = perCol[m.toLowerCase()] ?? 0;
      _source.setValue(_totalsRowId, m.toLowerCase(),
          NumberCell(double.parse(t.toStringAsFixed(1))));
      grand += t;
    }
    _source.setValue(_totalsRowId, 'total',
        NumberCell(double.parse(grand.toStringAsFixed(1))));
  }

  void _addMerges() {
    for (var q = 0; q < 4; q++) {
      _source.addMerge(MergeRange(
        anchorRow: _quarterRowId,
        anchorCol: _months[q * 3].toLowerCase(),
        rowSpan: 1,
        colSpan: 3,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Financial sheet (merges + freeze)')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: () => _controller.selectColumn(
                        _controller.columnLayout.indexOf['feb']!),
                    icon: const Icon(Icons.view_column, size: 14),
                    label: const Text('Select FEB column'),
                  ),
                  TextButton.icon(
                    onPressed: () => _controller.selectAll(),
                    icon: const Icon(Icons.select_all, size: 14),
                    label: const Text('Select all'),
                  ),
                  TextButton.icon(
                    onPressed: () => _controller.clearSelection(),
                    icon: const Icon(Icons.deselect, size: 14),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const HelpBanner(
                text:
                    'Two frozen header rows form a merged-cell header strip — '
                    'Q1/Q2/Q3/Q4 each span 3 month columns via MergeRange. '
                    'TOTAL row is bottom-frozen and re-shows on any scroll.',
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: UltimateTable(controller: _controller),
                ),
              ),
            ],
          ),
        ),
      );
}
