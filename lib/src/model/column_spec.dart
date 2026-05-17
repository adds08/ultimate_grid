import 'package:meta/meta.dart';

import 'cell_address.dart';
import 'cell_value.dart';
import 'freeze.dart';

/// Static description of a column. Live view state (current width, current
/// freeze side, current sort/filter) is owned by GridController, not here.
@immutable
class ColumnSpec {
  final ColId id;
  final String header;

  /// Default width if the controller has no override.
  final double defaultWidth;

  /// Minimum width when the user resizes.
  final double minWidth;

  /// Optional default freeze. Null = scrollable.
  final FrozenSide? defaultFrozen;

  /// Pin priority among frozen columns. Lower values render closer to the
  /// outside edge of the frozen strip. Used to deterministically order
  /// non-contiguous freezes like "freeze cols 1, 2, 8 to the left".
  final int defaultFreezePriority;

  /// Cell-type hint used by the default renderer/editor registry. Renderers
  /// may still inspect the actual [CellValue] subtype at paint time.
  final CellKind kind;

  /// Whether the column participates in sorting/filtering by default.
  final bool sortable;
  final bool filterable;

  /// Optional tag (e.g. "currency", "duration") consumed by user renderers.
  final String? tag;

  const ColumnSpec({
    required this.id,
    required this.header,
    this.defaultWidth = 120,
    this.minWidth = 40,
    this.defaultFrozen,
    this.defaultFreezePriority = 0,
    this.kind = CellKind.text,
    this.sortable = true,
    this.filterable = true,
    this.tag,
  });
}

enum CellKind { number, text, bool_, date, formula, custom }
