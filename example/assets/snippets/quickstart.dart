import 'package:ultimate_grid/ultimate_grid.dart';

// #docregion core-setup
final schema = GridSchema(
  columns: const [
    ColumnSpec(
      id: 'sku',
      header: 'SKU',
      defaultWidth: 110,
      defaultFrozen: FrozenSide.start,
    ),
    ColumnSpec(id: 'name', header: 'Product', defaultWidth: 220),
    ColumnSpec(
      id: 'price',
      header: 'Price',
      defaultWidth: 100,
      kind: CellKind.number,
    ),
  ],
  rows: [for (var i = 0; i < 100; i++) RowSpec(id: 'r$i')],
);

final source = MapGridDataSource(
  rowIds: [for (final r in schema.rows) r.id],
  colIds: [for (final c in schema.columns) c.id],
);
source.setValue('r0', 'sku', const TextCell('SKU-0001'));
source.setValue('r0', 'name', const TextCell('Widget A'));
source.setValue('r0', 'price', const NumberCell(19.99));

final controller = GridController(schema: schema, source: source);

// In your widget tree:
//   UltimateTable(controller: controller);
// #enddocregion core-setup
