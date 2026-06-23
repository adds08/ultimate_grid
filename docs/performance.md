# Performance

Ultimate Grid scales to millions of rows because the scrollable body does not
build a widget tree per cell. This guide explains how, and the one web caveat
to know.

## Custom-paint body

The scrollable middle body is a single `LeafRenderObjectWidget` (`UltimateBody`)
backed by a custom `RenderObject` (`RenderUltimateBody`). Instead of a widget
per cell, it paints cell text and grid lines directly onto the canvas. There is
one render object per visible column slice (left-frozen / middle / right-frozen),
sharing a synced vertical scroll position.

Consequences:

- **No per-cell `Element`/`RenderObject`.** A 5M-row source mounts roughly the
  same widget count as a 100-row one.
- The frozen strips (header, top/bottom-frozen rows) **do** use widget cells —
  they are few, and it keeps the editor wiring simple.
- Because body cells are painted (not laid out as text widgets), you can't
  drag-highlight a substring inside one body cell. Double-tap opens the in-cell
  editor for full text selection (see [Interaction](interaction.md)).

## Only the visible window is painted

On every frame the render object computes the first/last visible row and column
from the scroll offset using the precomputed cumulative-offset tables on
`ColumnLayout` / `RowLayout` (an `O(log n)` binary search via
`firstVisibleMiddle`). It then paints only that rectangle of cells. Scrolling is
`O(visible cells)`, independent of total row count.

## `ParagraphCache` (LRU)

Re-laying out the same text on every scroll tick would dominate the frame.
`ParagraphCache` is a bounded LRU of laid-out `TextPainter`s keyed by
`(text, style, align, maxWidth)` (with `maxWidth` rounded so float jitter
doesn't bust the key). The first time a `(text, style)` pair is seen it's laid
out and stored; later frames reuse it. When the cache fills (default capacity
1024), the oldest unused entry is evicted and disposed.

The table owns one cache for its lifetime; you don't manage it. A viewport
rarely shows more than a few hundred distinct `(text, style)` pairs at once, so
the cache stays small and warm.

## Scaling to ~5M rows

The example gallery includes a multi-million-row stress test. The combination
that makes it smooth:

- sparse storage in `MapGridDataSource` (only set cells allocate), or lazy
  paging via `AsyncGridDataSource` (only fetched pages allocate),
- derived layout computed once per controller revision (not per frame),
- visible-window-only painting, and
- the paragraph cache.

Keep the win: don't wrap body cells in widgets unless a column genuinely needs
interactivity — use `widgetColumns` for just those columns (see
[Cells & rendering](cells-and-rendering.md)).

## The web caveat: `Uint32List`, not `Uint64List`

JavaScript has no native 64-bit integers, so `Uint64List` is unsupported on
Flutter web. Every bitset in the package uses **`Uint32List`** (32 bits per
word) — notably the search-hit bitset in `ViewPipelineResult.searchHits`. This
is an internal detail, but it's why you'll see `>> 5` / `& 31` word arithmetic
in the pipeline rather than `>> 6` / `& 63`. If you write code that consumes
these bitsets, mirror the 32-bit word size.

## See also

- [Concepts](concepts.md) — why only the middle body is canvas-painted
- [Data sources](data-sources.md) — sparse storage and async paging
- [Cells & rendering](cells-and-rendering.md) — keeping the fast paint path
