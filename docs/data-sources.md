# Data sources

A `GridDataSource` supplies cell values. It is a `Listenable` with a monotonic
`revision` counter; the controller subscribes to it, so mutating data
automatically rebuilds derived view state. Two implementations ship.

The contract:

```dart
abstract class GridDataSource implements Listenable {
  Iterable<RowId> get rowIds;
  Iterable<ColId> get colIds;
  CellValue valueAt(RowId row, ColId col); // EmptyCell.instance when unset
  Object? metadataAt(RowId row, ColId col); // sparse side-channel; null when none
  int get revision;
  List<MergeRange> get merges; // const [] when none declared
}
```

## `MapGridDataSource`

A mutable, in-memory matrix-map. Storage is **sparse**: only `(row, col)` pairs
you actually set allocate, so a 5M-row source with a few thousand populated
cells stays cheap.

```dart
final source = MapGridDataSource(
  rowIds: [for (var i = 0; i < 1000; i++) 'r$i'],
  colIds: const ['sku', 'name', 'price'],
);

source.setValue('r0', 'name', const TextCell('Widget A'));
source.setValue('r0', 'price', const NumberCell(19.99));
```

Mutations bump `revision` and notify listeners (the controller repaints):

- `setValue(row, col, value)` — set a cell. Writing an `EmptyCell` **removes**
  the stored cell (sparse semantics).
- `setMetadata(row, col, payload)` — attach an invisible payload (tooltip text,
  a domain object). `null` clears it. Metadata is lazily allocated — zero cost
  when unused.
- `addRow` / `removeRow` / `addColumn` / `removeColumn`
- `reorderRows(next)` / `reorderColumns(next)` — `next` must be a permutation
  of the existing ids.
- `addMerge` / `removeMerge` / `clearMerges` (see below).

> `GridController.reorderRow(id, toIndex)` is a convenience that calls
> `reorderRows` — it only works when the bound source is a `MapGridDataSource`.

## `AsyncGridDataSource`

For "API → grid" pipelines without a pagination widget. You declare the total
row count and column list up front; cells load lazily, one page at a time.

```dart
final source = AsyncGridDataSource(
  rowIds: [for (var i = 0; i < 100000; i++) 'r$i'],
  colIds: const ['id', 'name', 'amount'],
  pageSize: 50, // default 50
  fetchRange: (startRow, endRowExclusive) async {
    final rows = await api.fetch(startRow, endRowExclusive);
    return AsyncPage(
      rowIds: [for (final r in rows) r.id],
      cells: {
        for (final r in rows)
          r.id: {
            'name': TextCell(r.name),
            'amount': NumberCell(r.amount),
          },
      },
    );
  },
);
```

How it behaves:

- When the grid reads a cell whose page hasn't loaded, the source kicks off
  `fetchRange` for that page and returns a **loading placeholder**
  (`loadingPlaceholder`, default `TextCell('…')`). When the page resolves, the
  cache absorbs it, `revision` bumps, and the grid repaints. No pagination
  component is needed.
- In-flight pages are tracked, so a page is fetched at most once even if many
  cells in it are read in the same frame.
- `prefetchRow(rowIndex)` — hint the source to start a page early (e.g. just
  past the viewport) without going through `valueAt`.
- `isRowLoaded(rowIndex)` — whether the covering page has loaded.
- `invalidate({page})` — drop a loaded page (or, with no argument, every page)
  so the next read re-fetches.

`AsyncGridDataSource` exposes no merges and no metadata.

## Cell merges (`MergeRange`)

A `MergeRange` paints one anchor cell across a `rowSpan × colSpan` rectangle;
the occluded cells are skipped. Merges reference cells by **schema id**, so
they stay correct across sort/filter/reorder.

```dart
source.addMerge(const MergeRange(
  anchorRow: 'q1',
  anchorCol: 'jan',
  rowSpan: 1,
  colSpan: 3, // "Q1" spans Jan/Feb/Mar
));
```

- `rowSpan` and `colSpan` must each be `>= 1`.
- If a merge's anchor or any occluded cell is currently filtered out, the merge
  is silently dropped for that view and the cells render normally.
- The controller turns the source's `merges` into a `MergeIndex` for the
  current view (`controller.mergeIndex`) — you rarely touch it directly.

## See also

- [Cells & rendering](cells-and-rendering.md) — what `CellValue`s the source returns
- [Concepts](concepts.md) — source vs. controller, the revision model
- [Performance](performance.md) — sparse storage and scaling
