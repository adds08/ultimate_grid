import 'package:meta/meta.dart';

import 'cell_address.dart';
import 'freeze.dart';

/// Static description of a row. Live view state (current height, current
/// freeze side) is owned by `GridController`, not here — mutate it via
/// `setRowHeight` / `setRowFreeze` instead of building a new [RowSpec].
@immutable
class RowSpec {
  /// Stable identifier used by [GridDataSource] to address cells in this
  /// row. Must be unique within the schema.
  final RowId id;

  /// Initial row height in logical pixels. The controller may override
  /// this at runtime via `setRowHeight`.
  final double defaultHeight;

  /// Optional default freeze. `null` (the default) means the row is
  /// scrollable; [FrozenSide.start] pins it to the top, [FrozenSide.end]
  /// to the bottom.
  final FrozenSide? defaultFrozen;

  /// Pin priority among frozen rows on the same side. Lower values render
  /// closer to the outside edge of the frozen strip. Lets a "Q1 / Q2" +
  /// "Jan / Feb" two-row frozen header strip preserve a deterministic
  /// order even when individual rows are reordered.
  final int defaultFreezePriority;

  /// Builds a row spec. Only [id] is required; the other fields fall back
  /// to sensible defaults.
  const RowSpec({
    required this.id,
    this.defaultHeight = 44,
    this.defaultFrozen,
    this.defaultFreezePriority = 0,
  });
}
