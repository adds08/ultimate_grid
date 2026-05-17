import '../model/cell_value.dart';
import 'view_pipeline.dart';

/// Convenience constructors for the most common filter shapes. All return
/// a [FilterPredicate] you can pass to `controller.setFilter(colId, …)`.
abstract final class Filters {
  /// Case-insensitive substring match on the cell's string representation.
  /// Empty needle ⇒ always true (caller should pass null instead to clear).
  static FilterPredicate textContains(String needle) {
    final lower = needle.toLowerCase();
    if (lower.isEmpty) return _alwaysTrue;
    return (value) {
      if (value is EmptyCell) return false;
      return value.toString().toLowerCase().contains(lower);
    };
  }

  /// True iff the cell's display string matches one of [values]. Integer
  /// `NumberCell`s match both `"3"` and `"3.0"`. `EmptyCell` matches `""`.
  static FilterPredicate oneOf(Iterable<String> values) {
    final set = values.toSet();
    return (value) {
      if (value is EmptyCell) return set.contains('');
      if (value is NumberCell) {
        final v = value.value;
        if (v == v.roundToDouble()) {
          if (set.contains(v.toStringAsFixed(0))) return true;
        }
      }
      return set.contains(value.toString());
    };
  }

  /// True iff the cell is a [NumberCell] within [min]..[max] inclusive.
  /// Either bound may be `null` to leave that side open.
  static FilterPredicate numberRange({double? min, double? max}) {
    return (value) {
      if (value is! NumberCell) return false;
      if (min != null && value.value < min) return false;
      if (max != null && value.value > max) return false;
      return true;
    };
  }

  /// Wrap a free-form predicate.
  static FilterPredicate where(bool Function(CellValue) test) => test;
}

/// How the pipeline treats the current search query.
enum SearchMode {
  /// Mark matching rows in the search-hit bitset; non-matches still render.
  /// (Default.)
  highlight,

  /// Drop non-matching rows from the view entirely.
  filter,
}

bool _alwaysTrue(CellValue _) => true;
