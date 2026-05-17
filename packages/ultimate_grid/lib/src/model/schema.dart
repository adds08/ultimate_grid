import 'package:meta/meta.dart';

import 'cell_address.dart';
import 'column_spec.dart';
import 'row_spec.dart';

/// Static description of the grid's columns + rows. Mutations to data flow
/// through GridDataSource; mutations to view state flow through GridController.
/// GridSchema itself is immutable.
@immutable
class GridSchema {
  final List<ColumnSpec> columns;
  final List<RowSpec> rows;
  final Map<ColId, ColumnSpec> _colIndex;
  final Map<RowId, RowSpec> _rowIndex;

  GridSchema({required this.columns, required this.rows})
      : _colIndex = {for (final c in columns) c.id: c},
        _rowIndex = {for (final r in rows) r.id: r} {
    assert(_colIndex.length == columns.length,
        'Duplicate column ids in GridSchema');
    assert(_rowIndex.length == rows.length,
        'Duplicate row ids in GridSchema');
  }

  ColumnSpec? column(ColId id) => _colIndex[id];
  RowSpec? row(RowId id) => _rowIndex[id];

  int get columnCount => columns.length;
  int get rowCount => rows.length;
}
