import 'package:meta/meta.dart';

@immutable
sealed class CellValue {
  const CellValue();

  bool get isEmpty => this is EmptyCell;
  Object? get raw;
}

final class EmptyCell extends CellValue {
  const EmptyCell();
  static const EmptyCell instance = EmptyCell();
  @override
  Object? get raw => null;
  @override
  String toString() => '';
}

final class NumberCell extends CellValue {
  final double value;
  const NumberCell(this.value);
  @override
  Object get raw => value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NumberCell && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value.toString();
}

final class TextCell extends CellValue {
  final String value;
  const TextCell(this.value);
  @override
  Object get raw => value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TextCell && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

final class BoolCell extends CellValue {
  final bool value;
  const BoolCell(this.value);
  @override
  Object get raw => value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BoolCell && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value.toString();
}

final class DateCell extends CellValue {
  final DateTime value;
  const DateCell(this.value);
  @override
  Object get raw => value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateCell && other.value.isAtSameMomentAs(value);
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value.toIso8601String();
}

/// Formula source + last-evaluated cache. Phase 1 ships no evaluator;
/// renderers display [cached] (or the raw source when [cached] is null).
final class FormulaCell extends CellValue {
  final String source;
  final CellValue? cached;
  const FormulaCell(this.source, {this.cached});
  @override
  Object? get raw => cached?.raw ?? source;
  FormulaCell withCached(CellValue? next) =>
      FormulaCell(source, cached: next);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormulaCell && other.source == source && other.cached == cached;
  @override
  int get hashCode => Object.hash(source, cached);
  @override
  String toString() => '=$source';
}

/// Escape hatch for callers that need to carry arbitrary payloads as a value.
/// Prefer [GridDataSource.metadataAt] when the payload is invisible/secondary —
/// metadata is sparse and zero-cost when unused. Use [CustomCell] only when
/// the payload IS the cell's visible value and a custom renderer will paint it.
final class CustomCell extends CellValue {
  final Object payload;
  const CustomCell(this.payload);
  @override
  Object get raw => payload;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CustomCell && other.payload == payload;
  @override
  int get hashCode => payload.hashCode;
  @override
  String toString() => payload.toString();
}
