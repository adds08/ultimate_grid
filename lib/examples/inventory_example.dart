import 'package:flutter/material.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

import 'shared.dart';

/// Simple inventory example — 60 rows, no async, no advanced wiring. The
/// minimum-viable shape: schema + source + controller + UltimateTable.
class InventoryExample extends StatefulWidget {
  const InventoryExample({super.key});

  @override
  State<InventoryExample> createState() => _InventoryExampleState();
}

class _InventoryExampleState extends State<InventoryExample> {
  late final MapGridDataSource _source;
  late final GridController _controller;

  @override
  void initState() {
    super.initState();
    final schema = _buildSchema();
    _source = _buildData(schema);
    _controller = GridController(schema: schema, source: _source);
  }

  GridSchema _buildSchema() => GridSchema(
        columns: const [
          ColumnSpec(
              id: 'sku',
              header: 'SKU',
              defaultWidth: 110,
              defaultFrozen: FrozenSide.start),
          ColumnSpec(id: 'name', header: 'Product', defaultWidth: 220),
          ColumnSpec(id: 'category', header: 'Category', defaultWidth: 130),
          ColumnSpec(
              id: 'stock',
              header: 'Stock',
              defaultWidth: 90,
              kind: CellKind.number),
          ColumnSpec(
              id: 'price',
              header: 'Price',
              defaultWidth: 100,
              kind: CellKind.number),
          ColumnSpec(
              id: 'supplier', header: 'Supplier', defaultWidth: 180),
          ColumnSpec(
              id: 'margin',
              header: 'Margin %',
              defaultWidth: 110,
              kind: CellKind.number,
              defaultFrozen: FrozenSide.end),
        ],
        rows: [
          for (var i = 0; i < 60; i++)
            RowSpec(id: 'p_${i.toString().padLeft(3, '0')}'),
        ],
      );

  MapGridDataSource _buildData(GridSchema schema) {
    const cats = ['Cable', 'Adapter', 'Battery', 'Sensor', 'Module'];
    const suppliers = ['Acme Corp', 'Globex', 'Initech', 'Soylent', 'Umbrella'];
    final src = MapGridDataSource(
      rowIds: [for (final r in schema.rows) r.id],
      colIds: [for (final c in schema.columns) c.id],
    );
    for (var i = 0; i < schema.rows.length; i++) {
      final id = schema.rows[i].id;
      final cat = cats[i % cats.length];
      final sup = suppliers[(i * 7) % suppliers.length];
      final price = 12.0 + (i * 3 % 47) + (i % 5) * 0.25;
      final cost = price * (0.45 + (i % 7) * 0.03);
      final margin = ((price - cost) / price) * 100;
      src.setValue(
          id, 'sku', TextCell('SKU-${(i + 1001).toString().padLeft(4, '0')}'));
      src.setValue(id, 'name',
          TextCell('$cat ${String.fromCharCode(65 + (i % 26))}${i % 100}'));
      src.setValue(id, 'category', TextCell(cat));
      src.setValue(id, 'stock', NumberCell((i * 13 % 200).toDouble()));
      src.setValue(
          id, 'price', NumberCell(double.parse(price.toStringAsFixed(2))));
      src.setValue(id, 'supplier', TextCell(sup));
      src.setValue(
          id, 'margin', NumberCell(double.parse(margin.toStringAsFixed(1))));
    }
    return src;
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
          const HelpBanner(
            text:
                'Minimal example — schema + MapGridDataSource + GridController '
                '+ UltimateTable. The simplest shape you can spin up.',
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
                headerBuilder: (ctx, colId) =>
                    HeaderLabel(controller: _controller, colId: colId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
