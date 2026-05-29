import 'package:flutter/material.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

class SelfCreatedExample extends StatefulWidget {
  const SelfCreatedExample({super.key});

  @override
  State<SelfCreatedExample> createState() => _SelfCreatedExampleState();
}

class _SelfCreatedExampleState extends State<SelfCreatedExample> {
  @override
  Widget build(BuildContext context) {
    final schema = GridSchema(
      columns: const [
        ColumnSpec(id: 'sku', header: 'SKU', defaultWidth: 110, defaultFrozen: FrozenSide.start),
        ColumnSpec(id: 'product', header: 'Product', defaultWidth: 220),
        ColumnSpec(id: 'price', header: 'Price', defaultWidth: 100, kind: CellKind.number),
      ],
      rows: [for (var i = 0; i < 1; i++) RowSpec(id: 'r$i')],
    );

    final source = MapGridDataSource(rowIds: [for (final r in schema.rows) r.id], colIds: [for (final c in schema.columns) c.id]);
    source.setValue('r0', 'sku', const TextCell('SKU-0001'));
    source.setValue('r0', 'product', const TextCell('Widget A'));
    source.setValue('r0', 'price', const NumberCell(19.99));

    final controller = GridController(schema: schema, source: source);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: UltimateTable(
        headerBuilder: (context, colId) {
          final col = schema.column(colId)!;
          return Text(col.header);
        },
        headerHeight: 80,
        headerMaxWidth: 200,
        onHeaderTap: (context, colId) => showDialog(
          context: context,
          builder: (context) => AlertDialog(title: Text('Header Tapped'), content: Text('You tapped on the header for column: $colId')),
        ),
        controller: controller,
      ),
    );
  }
}
