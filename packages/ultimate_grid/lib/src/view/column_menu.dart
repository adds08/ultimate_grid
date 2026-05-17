import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;

import '../controller/grid_controller.dart';
import '../filter_sort/filters.dart';
import '../filter_sort/view_pipeline.dart';
import '../model/cell_address.dart';
import '../model/column_spec.dart';
import '../model/freeze.dart';
import '../theme/grid_theme.dart';

/// Per-column popup menu. Sort asc / desc / off, pin left / right / none,
/// hide, resize-to-fit, filter (text, number range, or multi-value depending
/// on the column's [CellKind]). Designed to be opened from the header's
/// long-press / menu-button callback.
///
/// Open with `showUltimateColumnMenu(context: …, controller: …, colId: …)`.
Future<void> showUltimateColumnMenu({
  required BuildContext context,
  required GridController controller,
  required ColId colId,
  RelativeRect? position,
  GridTheme theme = GridTheme.mark85,
}) async {
  final box = context.findRenderObject() as RenderBox?;
  final overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox?;
  RelativeRect pos;
  if (position != null) {
    pos = position;
  } else if (box != null && overlay != null) {
    // Describe the header cell as an anchor rect in overlay coordinates.
    // `showMenu` opens the menu at the bottom-left of this rect when
    // there's room below — same shape that a normal `PopupMenuButton`
    // computes internally — so the animation lands smoothly under the
    // tapped cell.
    final cellTopLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final cellBottomRight = cellTopLeft + Offset(box.size.width, box.size.height);
    pos = RelativeRect.fromRect(
      Rect.fromPoints(cellTopLeft, cellBottomRight),
      Offset.zero & overlay.size,
    );
  } else {
    pos = const RelativeRect.fromLTRB(0, 0, 0, 0);
  }

  final action = await showMenu<_ColumnMenuAction>(
    context: context,
    position: pos,
    items: _buildItems(controller, colId),
  );
  if (action == null) return;
  if (!context.mounted) return;
  await _applyAction(context, controller, colId, action, theme);
}

enum _ColumnMenuAction {
  sortAsc,
  sortDesc,
  sortOff,
  pinLeft,
  pinRight,
  pinNone,
  hide,
  fit,
  filter,
  clearFilter,
}

/// One menu row. Uses Material defaults for height + interactive area so
/// the popup feels like a stock `PopupMenuButton`. The leading icon +
/// trailing check are the only ornamentation.
PopupMenuItem<_ColumnMenuAction> _row(
  _ColumnMenuAction value,
  IconData icon,
  String label, {
  bool active = false,
  Color? trailingColor,
}) {
  return PopupMenuItem<_ColumnMenuAction>(
    value: value,
    child: Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: active ? const Color(0xFFEA580C) : const Color(0xFF475569),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: trailingColor ??
                  (active
                      ? const Color(0xFFEA580C)
                      : const Color(0xFF0F172A)),
            ),
          ),
        ),
        if (active)
          const Icon(Icons.check, size: 16, color: Color(0xFFEA580C)),
      ],
    ),
  );
}

List<PopupMenuEntry<_ColumnMenuAction>> _buildItems(
  GridController controller,
  ColId colId,
) {
  final sortKey = controller.sortKeys.firstWhere(
    (k) => k.col == colId,
    orElse: () => const SortKey('', SortDirection.ascending),
  );
  final hasFilter = controller.filters.containsKey(colId);
  final frozen = controller.freezeOf(colId);
  return <PopupMenuEntry<_ColumnMenuAction>>[
    _row(_ColumnMenuAction.sortAsc, Icons.arrow_upward, 'Sort ascending',
        active: sortKey.col == colId &&
            sortKey.direction == SortDirection.ascending),
    _row(_ColumnMenuAction.sortDesc, Icons.arrow_downward, 'Sort descending',
        active: sortKey.col == colId &&
            sortKey.direction == SortDirection.descending),
    _row(_ColumnMenuAction.sortOff, Icons.clear, 'Clear sort'),
    const PopupMenuDivider(),
    _row(_ColumnMenuAction.pinLeft, Icons.push_pin_outlined, 'Pin to left',
        active: frozen == FrozenSide.start),
    _row(_ColumnMenuAction.pinRight, Icons.push_pin, 'Pin to right',
        active: frozen == FrozenSide.end),
    _row(_ColumnMenuAction.pinNone, Icons.location_off_outlined, 'Unpin'),
    const PopupMenuDivider(),
    _row(_ColumnMenuAction.hide, Icons.visibility_off_outlined, 'Hide column'),
    _row(_ColumnMenuAction.fit, Icons.straighten, 'Resize to fit'),
    const PopupMenuDivider(),
    _row(_ColumnMenuAction.filter, Icons.filter_alt_outlined, 'Filter…',
        active: hasFilter),
    if (hasFilter)
      _row(_ColumnMenuAction.clearFilter, Icons.filter_alt_off_outlined,
          'Clear filter',
          trailingColor: const Color(0xFFB91C1C)),
  ];
}

Future<void> _applyAction(
  BuildContext context,
  GridController controller,
  ColId colId,
  _ColumnMenuAction action,
  GridTheme theme,
) async {
  switch (action) {
    case _ColumnMenuAction.sortAsc:
      controller.setSortKeys([SortKey(colId, SortDirection.ascending)]);
    case _ColumnMenuAction.sortDesc:
      controller.setSortKeys([SortKey(colId, SortDirection.descending)]);
    case _ColumnMenuAction.sortOff:
      controller.setSortKeys(const []);
    case _ColumnMenuAction.pinLeft:
      controller.setColumnFreeze(colId, FrozenSide.start);
    case _ColumnMenuAction.pinRight:
      controller.setColumnFreeze(colId, FrozenSide.end);
    case _ColumnMenuAction.pinNone:
      controller.setColumnFreeze(colId, null);
    case _ColumnMenuAction.hide:
      controller.hideColumn(colId);
    case _ColumnMenuAction.fit:
      final spec = controller.schema.column(colId);
      final style = spec?.kind == CellKind.number
          ? theme.bodyNumericStyle
          : theme.bodyTextStyle;
      controller.fitColumnToText(
        id: colId,
        measure: (text) {
          final p = painting.TextPainter(
            text: painting.TextSpan(text: text, style: style),
            textDirection: painting.TextDirection.ltr,
            maxLines: 1,
          )..layout();
          final w = p.width;
          p.dispose();
          return w;
        },
      );
    case _ColumnMenuAction.filter:
      if (!context.mounted) return;
      await showUltimateFilterDialog(
        context: context,
        controller: controller,
        colId: colId,
      );
    case _ColumnMenuAction.clearFilter:
      controller.setFilter(colId, null);
  }
}

/// Dialog with a column-kind-appropriate filter input. Submitting writes a
/// [FilterPredicate] back via `controller.setFilter`.
Future<void> showUltimateFilterDialog({
  required BuildContext context,
  required GridController controller,
  required ColId colId,
}) async {
  final spec = controller.schema.column(colId);
  if (spec == null) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Filter ${spec.header}'),
        content: SizedBox(
          width: 320,
          child: _FilterInputForKind(
            controller: controller,
            colId: colId,
            kind: spec.kind,
          ),
        ),
      );
    },
  );
}

class _FilterInputForKind extends StatefulWidget {
  final GridController controller;
  final ColId colId;
  final CellKind kind;
  const _FilterInputForKind({
    required this.controller,
    required this.colId,
    required this.kind,
  });

  @override
  State<_FilterInputForKind> createState() => _FilterInputForKindState();
}

class _FilterInputForKindState extends State<_FilterInputForKind> {
  final _textCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kind == CellKind.number) ...[
          TextField(
            controller: _minCtrl,
            decoration: const InputDecoration(labelText: 'Min'),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _maxCtrl,
            decoration: const InputDecoration(labelText: 'Max'),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
        ] else
          TextField(
            controller: _textCtrl,
            decoration: const InputDecoration(labelText: 'Contains'),
            autofocus: true,
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                widget.controller.setFilter(widget.colId, null);
                Navigator.of(context).pop();
              },
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                _apply();
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ],
    );
  }

  void _apply() {
    if (widget.kind == CellKind.number) {
      final min = double.tryParse(_minCtrl.text);
      final max = double.tryParse(_maxCtrl.text);
      if (min == null && max == null) {
        widget.controller.setFilter(widget.colId, null);
      } else {
        widget.controller
            .setFilter(widget.colId, Filters.numberRange(min: min, max: max));
      }
      return;
    }
    final needle = _textCtrl.text.trim();
    if (needle.isEmpty) {
      widget.controller.setFilter(widget.colId, null);
    } else {
      widget.controller.setFilter(widget.colId, Filters.textContains(needle));
    }
  }
}
