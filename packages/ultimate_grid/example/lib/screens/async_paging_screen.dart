import 'package:flutter/material.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

import '_shared.dart';

class AsyncPagingScreen extends StatefulWidget {
  final GridTheme theme;
  const AsyncPagingScreen({super.key, this.theme = GridTheme.mark85});

  @override
  State<AsyncPagingScreen> createState() => _AsyncPagingScreenState();
}

class _AsyncPagingScreenState extends State<AsyncPagingScreen> {
  static const _rowCount = 100000;
  static const _pageSize = 50;
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

  late final AsyncGridDataSource _source;
  late final GridController _controller;
  late final List<RowId> _rowIds;
  int _pagesFetched = 0;
  int _latencyMs = 350;

  @override
  void initState() {
    super.initState();
    _rowIds = List<RowId>.generate(
      _rowCount,
      (i) => 'r${i.toString().padLeft(6, '0')}',
    );
    _buildSource();
  }

  void _buildSource() {
    const colIds = [
      'sku',
      'name',
      'category',
      'stock',
      'price',
      'active',
      'supplier',
    ];
    _source = AsyncGridDataSource(
      rowIds: _rowIds,
      colIds: colIds,
      pageSize: _pageSize,
      fetchRange: (start, end) async {
        await Future<void>.delayed(Duration(milliseconds: _latencyMs));
        if (mounted) setState(() => _pagesFetched++);
        final cells = <RowId, Map<ColId, CellValue>>{};
        for (var i = start; i < end; i++) {
          final cat = _categories[i % _categories.length];
          final sup = _suppliers[(i * 7) % _suppliers.length];
          final price = 12.0 + (i * 3 % 47) + (i % 5) * 0.25;
          final stock = (i * 13 % 200).toDouble();
          cells[_rowIds[i]] = {
            'sku': TextCell('SKU-${(i + 100000).toString().padLeft(7, '0')}'),
            'name': TextCell(
                '$cat ${String.fromCharCode(65 + (i % 26))}${i % 100}'),
            'category': TextCell(cat),
            'stock': NumberCell(stock),
            'price': NumberCell(double.parse(price.toStringAsFixed(2))),
            'active': BoolCell((i % 9) != 3),
            'supplier': TextCell(sup),
          };
        }
        return AsyncPage(rowIds: _rowIds.sublist(start, end), cells: cells);
      },
    );
    final schema = GridSchema(
      columns: const [
        ColumnSpec(
          id: 'sku',
          header: 'SKU',
          defaultWidth: 140,
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
          id: 'active',
          header: 'Active',
          defaultWidth: 80,
          kind: CellKind.bool_,
        ),
        ColumnSpec(id: 'supplier', header: 'Supplier', defaultWidth: 180),
      ],
      rows: [for (final id in _rowIds) RowSpec(id: id)],
    );
    _controller = GridController(schema: schema, source: _source);
  }

  @override
  void dispose() {
    _controller.dispose();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Simulated latency:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButton<int>(
                    value: _latencyMs,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('0 ms')),
                      DropdownMenuItem(value: 100, child: Text('100 ms')),
                      DropdownMenuItem(value: 350, child: Text('350 ms')),
                      DropdownMenuItem(value: 800, child: Text('800 ms')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _latencyMs = v);
                    },
                  ),
                  Text('Pages fetched: $_pagesFetched',
                      style: const TextStyle(fontSize: 12)),
                  const Text('Page size: $_pageSize',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              const HelpBanner(
                text:
                    '100k rows, fetched 50 at a time via AsyncGridDataSource. '
                    'Scroll fast to see "Loading…" placeholders flash before '
                    'pages resolve. Bump latency up to make it obvious.',
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
                    theme: widget.theme,
                    headerBuilder: (ctx, colId) =>
                        HeaderLabel(controller: _controller, colId: colId),
                  ),
                ),
              ),
            ],
          ),
        );
}
