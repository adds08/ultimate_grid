# Getting started

Ultimate Grid is a scalable, themable 2D data-grid. The core library depends
only on `flutter/widgets.dart` — no Material or Cupertino.

## Install

```yaml
dependencies:
  ultimate_grid: ^0.1.1
```

A single import gives you the whole public API:

```dart
import 'package:ultimate_grid/ultimate_grid.dart';
```

## The minimal grid

A grid needs three objects wired together:

- a **`GridSchema`** — the static shape (columns + rows),
- a **`GridDataSource`** — the cell values, and
- a **`GridController`** — the runtime view state.

You hand the controller to an `UltimateTable` widget.

```dart
import 'package:flutter/widgets.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

class MiniGrid extends StatefulWidget {
  const MiniGrid({super.key});
  @override
  State<MiniGrid> createState() => _MiniGridState();
}

class _MiniGridState extends State<MiniGrid> {
  late final MapGridDataSource source;
  late final GridController controller;

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
        ColumnSpec(
          id: 'price',
          header: 'Price',
          defaultWidth: 100,
          kind: CellKind.number,
        ),
      ],
      rows: [for (var i = 0; i < 100; i++) RowSpec(id: 'r$i')],
    );

    source = MapGridDataSource(
      rowIds: [for (final r in schema.rows) r.id],
      colIds: [for (final c in schema.columns) c.id],
    );
    source.setValue('r0', 'sku', const TextCell('SKU-0001'));
    source.setValue('r0', 'name', const TextCell('Widget A'));
    source.setValue('r0', 'price', const NumberCell(19.99));

    controller = GridController(schema: schema, source: source);
  }

  @override
  void dispose() {
    controller.dispose();
    source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UltimateTable(controller: controller);
}
```

`UltimateTable` fills the constraints it's given — place it inside an
`Expanded`, a `SizedBox`, or any box with bounded height/width.

Notes that matter from the start:

- Both `MapGridDataSource` and `GridController` are `ChangeNotifier`s — dispose
  them when your `State` is torn down.
- `ColumnSpec.kind` is a hint (defaults to `CellKind.text`). It drives the
  default renderer, the in-cell editor's parsing, and numeric alignment. See
  [Cells & rendering](cells-and-rendering.md).
- A grid with no `headerBuilder` shows no header row. To render column headers,
  pass `headerBuilder:` to `UltimateTable` (see [Columns](columns.md)).

## Running the example app

A gallery of demos — inventory, a merged financial sheet, 100k-row async
paging, search & filter UI, theme switching, and a multi-million-row stress
test — ships in `example/`.

```bash
cd example
flutter run -d chrome
```

Drop `-d chrome` to run on whatever device is connected. The live build of the
same gallery is at <https://adds08.github.io/ultimate_grid/>.

## See also

- [Concepts](concepts.md) — what each of the four objects actually does
- [Columns](columns.md) — headers, freezing, widths, resize/reorder
- [Data sources](data-sources.md) — sparse storage and async paging
