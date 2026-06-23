import 'package:meta/meta.dart';

import 'cell_address.dart';
import 'column_spec.dart';
import 'row_spec.dart';

/// Static description of the grid's columns + rows. Mutations to data flow
/// through [GridDataSource]; mutations to view state flow through
/// `GridController`. [GridSchema] itself is immutable — build a new one if
/// the structural shape of the grid changes.
@immutable
class GridSchema {
  /// Column specs in their declared order. Visible column order at runtime
  /// is controlled by `GridController.columnOrder`.
  final List<ColumnSpec> columns;

  /// Row specs in their declared order. Visible row order at runtime is
  /// the order returned by the data source's `rowIds`, post-sort / filter.
  final List<RowSpec> rows;

  final Map<ColId, ColumnSpec> _colIndex;
  final Map<RowId, RowSpec> _rowIndex;

  /// Builds a schema from the given column and row specs. Asserts that
  /// every `ColumnSpec.id` is unique and every `RowSpec.id` is unique
  /// within their respective lists.
  GridSchema({required this.columns, required this.rows})
    : _colIndex = {for (final c in columns) c.id: c},
      _rowIndex = {for (final r in rows) r.id: r} {
    assert(
      _colIndex.length == columns.length,
      'Duplicate column ids in GridSchema',
    );
    assert(_rowIndex.length == rows.length, 'Duplicate row ids in GridSchema');
  }

  /// Looks up a [ColumnSpec] by id in O(1). Returns `null` if no column
  /// with that id was declared.
  ColumnSpec? column(ColId id) => _colIndex[id];

  /// Looks up a [RowSpec] by id in O(1). Returns `null` if no row with
  /// that id was declared.
  RowSpec? row(RowId id) => _rowIndex[id];

  /// Total number of declared columns. This is the schema count; the
  /// number of *visible* columns may be lower if some are hidden via
  /// `GridController.hideColumn`.
  int get columnCount => columns.length;

  /// Total number of declared rows. This is the schema count; the number
  /// of *visible* rows may be lower if filters or search are active.
  int get rowCount => rows.length;
}
