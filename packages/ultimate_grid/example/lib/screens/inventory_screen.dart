import 'package:flutter/material.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

import '_shared.dart';

class InventoryScreen extends StatefulWidget {
  final GridTheme theme;
  const InventoryScreen({super.key, this.theme = GridTheme.mark85});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final MapGridDataSource _source;
  late final GridController _controller;

  @override
  void initState() {
    super.initState();
    final schema = GridSchema(
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
        ColumnSpec(id: 'supplier', header: 'Supplier', defaultWidth: 180),
        ColumnSpec(
          id: 'margin',
          header: 'Margin %',
          defaultWidth: 110,
          kind: CellKind.number,
          defaultFrozen: FrozenSide.end,
        ),
      ],
      rows: [
        for (var i = 0; i < 60; i++)
          RowSpec(id: 'p_${i.toString().padLeft(3, '0')}'),
      ],
    );

    _source = MapGridDataSource(
      rowIds: [for (final r in schema.rows) r.id],
      colIds: [for (final c in schema.columns) c.id],
    );

    const cats = ['Cable', 'Adapter', 'Battery', 'Sensor', 'Module'];
    const suppliers = ['Acme Corp', 'Globex', 'Initech', 'Soylent', 'Umbrella'];
    for (var i = 0; i < schema.rows.length; i++) {
      final id = schema.rows[i].id;
      final cat = cats[i % cats.length];
      final sup = suppliers[(i * 7) % suppliers.length];
      final price = 12.0 + (i * 3 % 47) + (i % 5) * 0.25;
      final cost = price * (0.45 + (i % 7) * 0.03);
      final margin = ((price - cost) / price) * 100;
      _source.setValue(
        id,
        'sku',
        TextCell('SKU-${(i + 1001).toString().padLeft(4, '0')}'),
      );
      _source.setValue(
        id,
        'name',
        TextCell('$cat ${String.fromCharCode(65 + (i % 26))}${i % 100}'),
      );
      _source.setValue(id, 'category', TextCell(cat));
      _source.setValue(id, 'stock', NumberCell((i * 13 % 200).toDouble()));
      _source.setValue(
        id,
        'price',
        NumberCell(double.parse(price.toStringAsFixed(2))),
      );
      _source.setValue(id, 'supplier', TextCell(sup));
      _source.setValue(
        id,
        'margin',
        NumberCell(double.parse(margin.toStringAsFixed(1))),
      );
    }

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
              const HelpBanner(
                text:
                    'Minimal shape — schema + MapGridDataSource + '
                    'GridController + UltimateTable. SKU and Margin % are '
                    'frozen to opposite edges.',
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
