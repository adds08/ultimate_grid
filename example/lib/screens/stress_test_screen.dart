import 'package:flutter/material.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

import '_support/synthetic_data_source.dart';

/// Stress-test example: scroll through up to 5 million rows.
///
/// Demonstrates that the package's canvas-paint body scales — only the
/// visible window (~30 rows) is ever painted, regardless of the total row
/// count. The dropdown lets the user bump the row count up to verify how
/// the controller-build / pipeline timings behave.
class StressTestExample extends StatefulWidget {
  const StressTestExample({super.key});

  @override
  State<StressTestExample> createState() => _StressTestExampleState();
}

class _StressTestExampleState extends State<StressTestExample> {
  static const _rowCountChoices = <int>[10000, 100000, 1000000, 5000000];

  int _rowCount = 100000;
  final GridSchema _schema = _buildSchema();
  late GridController _controller;
  late SyntheticGridDataSource _source;
  int _buildMs = 0;

  @override
  void initState() {
    super.initState();
    _build();
  }

  static GridSchema _buildSchema() {
    return GridSchema(
      columns: const [
        ColumnSpec(
          id: 'sku',
          header: 'SKU',
          defaultWidth: 110,
          defaultFrozen: FrozenSide.start,
        ),
        ColumnSpec(id: 'name', header: 'Product', defaultWidth: 220),
        ColumnSpec(id: 'category', header: 'Category', defaultWidth: 130),
        ColumnSpec(
          id: 'stock',
          header: 'Stock',
          defaultWidth: 90,
          kind: CellKind.number,
        ),
        ColumnSpec(
          id: 'price',
          header: 'Price',
          defaultWidth: 100,
          kind: CellKind.number,
        ),
        ColumnSpec(
          id: 'cost',
          header: 'Cost',
          defaultWidth: 100,
          kind: CellKind.number,
        ),
        ColumnSpec(
          id: 'margin',
          header: 'Margin %',
          defaultWidth: 100,
          kind: CellKind.number,
        ),
        ColumnSpec(
          id: 'active',
          header: 'Active',
          defaultWidth: 80,
          kind: CellKind.bool_,
        ),
        ColumnSpec(
          id: 'restock',
          header: 'Restock',
          defaultWidth: 130,
          kind: CellKind.date,
        ),
        ColumnSpec(
          id: 'supplier',
          header: 'Supplier',
          defaultWidth: 180,
          defaultFrozen: FrozenSide.end,
        ),
      ],
      rows: const [],
    );
  }

  void _build() {
    final sw = Stopwatch()..start();
    _source = SyntheticGridDataSource(
      rowCount: _rowCount,
      colIds: const [
        'sku',
        'name',
        'category',
        'stock',
        'price',
        'cost',
        'margin',
        'active',
        'restock',
        'supplier',
      ],
      generator: _generate,
    );
    _controller = GridController(schema: _schema, source: _source);
    sw.stop();
    _buildMs = sw.elapsedMilliseconds;
    setState(() {});
  }

  static const _categories = [
    'Cable',
    'Adapter',
    'Battery',
    'Sensor',
    'Module',
  ];
  static const _suppliers = [
    'Acme Corp',
    'Globex',
    'Initech',
    'Soylent',
    'Umbrella',
  ];

  CellValue _generate(int i, ColId colId) {
    final cat = _categories[i % _categories.length];
    final sup = _suppliers[(i * 7) % _suppliers.length];
    final price = 12.0 + (i * 3 % 47) + (i % 5) * 0.25;
    final cost = price * (0.45 + (i % 7) * 0.03);
    final margin = ((price - cost) / price) * 100;
    final stock = (i * 13 % 200).toDouble();
    final active = (i % 9) != 3;

    switch (colId) {
      case 'sku':
        return TextCell('SKU-${(i + 1001).toString().padLeft(7, '0')}');
      case 'name':
        return TextCell('$cat ${String.fromCharCode(65 + (i % 26))}${i % 100}');
      case 'category':
        return TextCell(cat);
      case 'stock':
        return NumberCell(stock);
      case 'price':
        return NumberCell(double.parse(price.toStringAsFixed(2)));
      case 'cost':
        return NumberCell(double.parse(cost.toStringAsFixed(2)));
      case 'margin':
        return NumberCell(double.parse(margin.toStringAsFixed(1)));
      case 'active':
        return BoolCell(active);
      case 'restock':
        return DateCell(DateTime(2026, 1, 1).add(Duration(days: i % 365)));
      case 'supplier':
        return TextCell(sup);
    }
    return EmptyCell.instance;
  }

  @override
  void dispose() {
    _controller.dispose();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolbar(),
          const SizedBox(height: 8),
          _statsBanner(),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: UltimateTable(
                key: ValueKey(_rowCount),
                controller: _controller,
                headerBuilder: (ctx, colId) => Text(
                  _controller.schema.column(colId)?.header ?? colId,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Row count:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        DropdownButton<int>(
          value: _rowCount,
          isDense: true,
          items: [
            for (final n in _rowCountChoices)
              DropdownMenuItem<int>(value: n, child: Text(_format(n))),
          ],
          onChanged: (n) {
            if (n == null || n == _rowCount) return;
            setState(() => _rowCount = n);
            _controller.dispose();
            _source.dispose();
            _build();
          },
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: () {
            _build();
          },
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Rebuild'),
        ),
      ],
    );
  }

  Widget _statsBanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, size: 16, color: Color(0xFFEA580C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_format(_rowCount)} rows × ${_schema.columns.length} cols  '
              '·  controller built in $_buildMs ms  ·  '
              'visible window is always ~30 rows (canvas paint, no widgets '
              'per cell).  Scroll the body to verify smoothness.',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static String _format(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)} M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)} k';
    }
    return n.toString();
  }
}
