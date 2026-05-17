/// Which edge a frozen row or column should pin to.
///
/// Applies in both axes: a column with `defaultFrozen: FrozenSide.start`
/// pins to the **left** edge (or right edge in RTL); a row with
/// `defaultFrozen: FrozenSide.end` pins to the **bottom**.
///
/// Pin priority among frozen items in the same strip is controlled by
/// `defaultFreezePriority` on `ColumnSpec` / `RowSpec` — lower values
/// render closer to the outside edge of the strip, so non-contiguous
/// freezes (e.g. "freeze columns 1, 2, and 8 to the left") land in a
/// deterministic order.
enum FrozenSide {
  /// Pin to the leading edge: left for columns, top for rows.
  start,

  /// Pin to the trailing edge: right for columns, bottom for rows.
  end,
}
