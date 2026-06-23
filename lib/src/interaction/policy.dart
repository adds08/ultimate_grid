import 'package:meta/meta.dart';

import '../model/cell_address.dart';

/// Resolves an optional attribute [T] for a given cell.
///
/// The same shape powers per-cell styles, hover/tap handlers, tooltips,
/// badges, and conditional formatting. The contract is deliberately tiny:
/// return [T] when the cell has the attribute, null otherwise.
///
/// Implementations MUST NOT allocate per-cell objects up front when the
/// "off" state is meant to cost nothing. Predicate-based policies should
/// compute on demand; map-based policies should only hold entries for
/// cells that have the attribute set.
abstract class InteractionPolicy<T extends Object> {
  const InteractionPolicy();

  T? at(int rowIndex, int colIndex, RowId row, ColId col);

  /// Compose this policy with [other]. Entries from [other] win when both
  /// resolve a value (override semantics).
  InteractionPolicy<T> overriddenBy(InteractionPolicy<T> other) =>
      _CompositePolicy<T>(base: this, top: other);
}

/// Explicit, address-keyed entries. Memory = O(#entries), not O(#cells).
class MapPolicy<T extends Object> extends InteractionPolicy<T> {
  final Map<CellAddress, T> entries;
  const MapPolicy(this.entries);

  @override
  T? at(int rowIndex, int colIndex, RowId row, ColId col) =>
      entries[CellAddress(row, col)];
}

/// Rule-driven. The predicate is evaluated lazily — typically at paint or
/// hit-test time — so a policy that fires on millions of cells holds zero
/// per-cell state.
class PredicatePolicy<T extends Object> extends InteractionPolicy<T> {
  final T? Function(int rowIndex, int colIndex, RowId row, ColId col) rule;
  const PredicatePolicy(this.rule);

  @override
  T? at(int rowIndex, int colIndex, RowId row, ColId col) =>
      rule(rowIndex, colIndex, row, col);

  /// Helper: "every cell where both indices are even".
  static PredicatePolicy<T> evenCells<T extends Object>(T value) =>
      PredicatePolicy<T>(
        (r, c, _, __) => (r.isEven && c.isEven) ? value : null,
      );
}

@immutable
class _CompositePolicy<T extends Object> extends InteractionPolicy<T> {
  final InteractionPolicy<T> base;
  final InteractionPolicy<T> top;
  const _CompositePolicy({required this.base, required this.top});

  @override
  T? at(int rowIndex, int colIndex, RowId row, ColId col) =>
      top.at(rowIndex, colIndex, row, col) ??
      base.at(rowIndex, colIndex, row, col);
}
