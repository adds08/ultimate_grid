import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../model/cell_address.dart';
import '../model/cell_value.dart';
import '../source/grid_data_source.dart';

enum SortDirection { ascending, descending }

@immutable
class SortKey {
  final ColId col;
  final SortDirection direction;
  final Comparator<CellValue>? comparator;
  const SortKey(this.col, this.direction, {this.comparator});
}

typedef FilterPredicate = bool Function(CellValue value);

/// Result of running [ViewPipeline.run] in a single pass.
///
/// [viewRowIndices] is the row order to render: indices into the data source's
/// original row list, post-filter and post-sort. [searchHits] marks rows whose
/// values matched the current search query — useful for highlight-only mode.
@immutable
class ViewPipelineResult {
  /// Flat indices into [GridDataSource.rowIds], in render order.
  final Int32List viewRowIndices;

  /// Bitset over [viewRowIndices]: bit i set ⇒ row at viewRowIndices[i] hit
  /// the search. 32 bits per word — Uint64List is unsupported on Flutter web.
  /// Empty when search is inactive.
  final Uint32List searchHits;

  /// True when [searchHits] should be consulted.
  final bool hasSearch;

  const ViewPipelineResult({
    required this.viewRowIndices,
    required this.searchHits,
    required this.hasSearch,
  });

  bool isSearchHit(int viewIndex) {
    if (!hasSearch) return false;
    final word = viewIndex >> 5;
    if (word >= searchHits.length) return false;
    final bit = viewIndex & 31;
    return (searchHits[word] & (1 << bit)) != 0;
  }

  int get length => viewRowIndices.length;
}

/// Single-pass derivation: filter → sort → search. Each step touches the row
/// list at most once. Output is read-only and safe to share with renderers.
abstract final class ViewPipeline {
  static ViewPipelineResult run({
    required GridDataSource source,
    required List<SortKey> sortKeys,
    required Map<ColId, FilterPredicate> filters,
    required String query,
    bool searchFiltersRows = false,
  }) {
    final rowIds = source.rowIds.toList(growable: false);
    final filtersEntries = filters.entries.toList(growable: false);
    final hasFilters = filtersEntries.isNotEmpty;

    // Pass 1: filter — produce surviving original indices.
    final survivors = <int>[];
    for (var i = 0; i < rowIds.length; i++) {
      if (!hasFilters) {
        survivors.add(i);
        continue;
      }
      var keep = true;
      for (final f in filtersEntries) {
        if (!f.value(source.valueAt(rowIds[i], f.key))) {
          keep = false;
          break;
        }
      }
      if (keep) survivors.add(i);
    }

    // Pass 2: sort — stable merge by sortKeys order.
    if (sortKeys.isNotEmpty) {
      survivors.sort((aIdx, bIdx) {
        for (final key in sortKeys) {
          final av = source.valueAt(rowIds[aIdx], key.col);
          final bv = source.valueAt(rowIds[bIdx], key.col);
          final cmp = (key.comparator ?? _defaultComparator)(av, bv);
          if (cmp != 0) {
            return key.direction == SortDirection.ascending ? cmp : -cmp;
          }
        }
        return 0;
      });
    }

    // Materialize as Int32List for cheap renderer access.
    final view = Int32List(survivors.length);
    for (var i = 0; i < survivors.length; i++) {
      view[i] = survivors[i];
    }

    // Pass 3: search.
    //
    // In `highlight` mode we keep every row and just mark matches in a
    // bitset; in `filter` mode we drop non-matches outright and skip the
    // bitset (every kept row is a match).
    final hasSearch = query.isNotEmpty;
    if (hasSearch) {
      final needle = query.toLowerCase();
      final colIds = source.colIds.toList(growable: false);
      if (searchFiltersRows) {
        final keptOriginalIndices = <int>[];
        for (var i = 0; i < view.length; i++) {
          final rowId = rowIds[view[i]];
          for (final c in colIds) {
            if (_valueContains(source.valueAt(rowId, c), needle)) {
              keptOriginalIndices.add(view[i]);
              break;
            }
          }
        }
        final kept = Int32List(keptOriginalIndices.length);
        for (var i = 0; i < keptOriginalIndices.length; i++) {
          kept[i] = keptOriginalIndices[i];
        }
        return ViewPipelineResult(
          viewRowIndices: kept,
          searchHits: Uint32List(0),
          hasSearch: false,
        );
      }
      final wordCount = (view.length + 31) >> 5;
      final hits = Uint32List(wordCount);
      for (var i = 0; i < view.length; i++) {
        final rowId = rowIds[view[i]];
        for (final c in colIds) {
          if (_valueContains(source.valueAt(rowId, c), needle)) {
            hits[i >> 5] |= 1 << (i & 31);
            break;
          }
        }
      }
      return ViewPipelineResult(
        viewRowIndices: view,
        searchHits: hits,
        hasSearch: true,
      );
    }

    return ViewPipelineResult(
      viewRowIndices: view,
      searchHits: Uint32List(0),
      hasSearch: false,
    );
  }

  static int _defaultComparator(CellValue a, CellValue b) {
    if (a is EmptyCell) return b is EmptyCell ? 0 : 1;
    if (b is EmptyCell) return -1;
    if (a is NumberCell && b is NumberCell) {
      return a.value.compareTo(b.value);
    }
    if (a is BoolCell && b is BoolCell) {
      return (a.value ? 1 : 0).compareTo(b.value ? 1 : 0);
    }
    if (a is DateCell && b is DateCell) {
      return a.value.compareTo(b.value);
    }
    return a.toString().compareTo(b.toString());
  }

  static bool _valueContains(CellValue v, String lowerNeedle) {
    if (v is EmptyCell) return false;
    return v.toString().toLowerCase().contains(lowerNeedle);
  }
}
