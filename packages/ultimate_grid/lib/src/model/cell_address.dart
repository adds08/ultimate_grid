import 'package:meta/meta.dart';

typedef RowId = String;
typedef ColId = String;

@immutable
final class CellAddress {
  final RowId row;
  final ColId col;
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
