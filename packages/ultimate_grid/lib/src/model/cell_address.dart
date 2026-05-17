import 'package:meta/meta.dart';

/// Stable identity for a row across reorder / sort / filter. Rows are
/// addressed by [RowId] in the data source so the view can rearrange them
/// without invalidating cells. Typedef over [String] for ergonomic literal
/// IDs (`'r0'`, `'invoice_2026_05'`) without losing string-API access.
typedef RowId = String;

/// Stable identity for a column across reorder / hide / freeze. Mirrors
/// [RowId]: a typedef over [String] so column references can be written as
/// `'sku'` or `'price'` inline.
typedef ColId = String;

/// A `(row, column)` pair pointing at a single cell. Used by
/// `InteractionPolicy` keys and any API that needs to address one specific
/// cell rather than a range. Equality and `hashCode` are value-based, so
/// `CellAddress`es can be used as `Map` / `Set` keys.
@immutable
final class CellAddress {
  /// Identifier of the row this address points at.
  final RowId row;

  /// Identifier of the column this address points at.
  final ColId col;

  /// Builds an address from a row id + column id pair.
  const CellAddress(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellAddress && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}
