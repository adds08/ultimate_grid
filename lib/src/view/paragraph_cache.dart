import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Bounded LRU cache of laid-out [TextPainter]s, keyed by the tuple
/// `(text, style, textAlign, maxWidth)`.
///
/// The custom render-object body paints one text-bearing cell per visible
/// (row, col) pair every frame; without a cache that would re-layout the
/// same paragraph on every scroll tick. With this cache, the first time a
/// (text, style) pair is seen the painter is laid out and stored; subsequent
/// frames reuse the laid-out painter.
///
/// Capacity is intentionally small — viewports rarely show more than a few
/// hundred distinct (text, style) pairs at once. When the cache fills, the
/// oldest unused entry is evicted.
class ParagraphCache {
  ParagraphCache({this.capacity = 1024});

  final int capacity;
  final LinkedHashMap<int, TextPainter> _entries =
      LinkedHashMap<int, TextPainter>();

  TextPainter acquire({
    required String text,
    required TextStyle style,
    required TextAlign align,
    required double maxWidth,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    // Round maxWidth so float jitter doesn't bust the cache key.
    final widthKey = (maxWidth * 4).round();
    final key = Object.hash(text, style.hashCode, align.index, widthKey);
    final existing = _entries.remove(key);
    if (existing != null) {
      _entries[key] = existing; // touch
      return existing;
    }
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: textDirection,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth < 0 ? 0 : maxWidth);
    _entries[key] = painter;
    if (_entries.length > capacity) {
      final firstKey = _entries.keys.first;
      final dropped = _entries.remove(firstKey);
      dropped?.dispose();
    }
    return painter;
  }

  void clear() {
    for (final p in _entries.values) {
      p.dispose();
    }
    _entries.clear();
  }

  int get length => _entries.length;
}

/// Tiny helper for callers that want to paint a single text run directly
/// without managing a [ParagraphCache] (mostly tests). Allocates per call —
/// don't use from a hot paint path.
void paintTextDirect({
  required ui.Canvas canvas,
  required Offset offset,
  required String text,
  required TextStyle style,
  required TextAlign align,
  required double maxWidth,
}) {
  final p = TextPainter(
    text: TextSpan(text: text, style: style),
    textAlign: align,
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  p.paint(canvas, offset);
  p.dispose();
}
