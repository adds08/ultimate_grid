import 'package:flutter/widgets.dart';

/// Tiny replacement for linked_scroll_controller — keeps multiple
/// ScrollControllers locked to the same offset without re-entrant updates.
///
/// Owns its child controllers; dispose the group to dispose them all.
class SyncedScrollGroup {
  final List<ScrollController> _controllers = [];
  bool _suppress = false;

  ScrollController attach({double initialOffset = 0}) {
    final c = ScrollController(initialScrollOffset: initialOffset);
    c.addListener(() => _onMoved(c));
    _controllers.add(c);
    return c;
  }

  void _onMoved(ScrollController source) {
    if (_suppress) return;
    if (!source.hasClients) return;
    final target = source.offset;
    _suppress = true;
    try {
      for (final c in _controllers) {
        if (identical(c, source)) continue;
        if (!c.hasClients) continue;
        if (c.offset == target) continue;
        c.jumpTo(target);
      }
    } finally {
      _suppress = false;
    }
  }

  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
  }
}
