import 'dart:async';

import 'package:flutter/painting.dart' as painting;
import 'package:flutter/widgets.dart';

import '../controller/grid_controller.dart';
import '../filter_sort/view_pipeline.dart';
import '../model/cell_address.dart';
import '../model/column_spec.dart';
import '../model/freeze.dart';
import '../theme/grid_theme.dart';

/// Column menu actions that can be performed on a column.
enum ColumnMenuAction {
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

/// State snapshot of a column, passed to menu builders so they can
/// render active indicators (sort direction, filter presence, pin state).
class ColumnMenuState {
  final ColId colId;
  final String header;
  final CellKind kind;
  final SortDirection? currentSortDirection;
  final bool hasFilter;
  final FrozenSide? frozenSide;

  const ColumnMenuState({
    required this.colId,
    required this.header,
    required this.kind,
    this.currentSortDirection,
    this.hasFilter = false,
    this.frozenSide,
  });
}

/// Signature for a custom column menu builder.
///
/// Receives the build context, controller, column state, and a callback
/// to apply an action. The builder is responsible for showing a popup/menu
/// and calling [onAction] with the user's selection.
typedef ColumnMenuBuilder = Future<void> Function({
  required BuildContext context,
  required GridController controller,
  required ColumnMenuState columnState,
  required void Function(ColumnMenuAction action) onAction,
});

/// Signature for a custom filter dialog builder.
typedef FilterDialogBuilder = Future<void> Function({
  required BuildContext context,
  required GridController controller,
  required ColId colId,
  required CellKind kind,
  required String header,
});

/// Extract the current state of a column for menu display.
ColumnMenuState getColumnMenuState(GridController controller, ColId colId) {
  final spec = controller.schema.column(colId);
  final sortKey = controller.sortKeys
      .where((k) => k.col == colId)
      .firstOrNull;
  final hasFilter = controller.filters.containsKey(colId);
  final frozen = controller.freezeOf(colId);

  return ColumnMenuState(
    colId: colId,
    header: spec?.header ?? colId,
    kind: spec?.kind ?? CellKind.text,
    currentSortDirection: sortKey?.col == colId ? sortKey?.direction : null,
    hasFilter: hasFilter,
    frozenSide: frozen,
  );
}

/// Apply a [ColumnMenuAction] to the controller.
///
/// This is framework-agnostic — only touches the controller, no UI.
/// Call from your custom menu builder's `onAction` callback, or use
/// directly after `showUltimateColumnMenu`.
Future<void> applyColumnMenuAction(
  BuildContext context,
  GridController controller,
  ColId colId,
  ColumnMenuAction action, {
  GridTheme theme = GridTheme.mark85,
  FilterDialogBuilder? filterDialogBuilder,
}) async {
  switch (action) {
    case ColumnMenuAction.sortAsc:
      controller.setSortKeys([SortKey(colId, SortDirection.ascending)]);
    case ColumnMenuAction.sortDesc:
      controller.setSortKeys([SortKey(colId, SortDirection.descending)]);
    case ColumnMenuAction.sortOff:
      controller.setSortKeys(const []);
    case ColumnMenuAction.pinLeft:
      controller.setColumnFreeze(colId, FrozenSide.start);
    case ColumnMenuAction.pinRight:
      controller.setColumnFreeze(colId, FrozenSide.end);
    case ColumnMenuAction.pinNone:
      controller.setColumnFreeze(colId, null);
    case ColumnMenuAction.hide:
      controller.hideColumn(colId);
    case ColumnMenuAction.fit:
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
    case ColumnMenuAction.filter:
      if (!context.mounted) return;
      if (filterDialogBuilder != null) {
        final spec = controller.schema.column(colId);
        await filterDialogBuilder(
          context: context,
          controller: controller,
          colId: colId,
          kind: spec?.kind ?? CellKind.text,
          header: spec?.header ?? colId,
        );
      }
    case ColumnMenuAction.clearFilter:
      controller.setFilter(colId, null);
  }
}

/// Framework-agnostic entry point for column menus.
///
/// If [menuBuilder] is provided, delegates to it. Otherwise falls back
/// to a minimal painted overlay menu with sort/pin/filter actions.
Future<void> showUltimateColumnMenu({
  required BuildContext context,
  required GridController controller,
  required ColId colId,
  GridTheme theme = GridTheme.mark85,
  ColumnMenuBuilder? menuBuilder,
  FilterDialogBuilder? filterDialogBuilder,
}) async {
  final state = getColumnMenuState(controller, colId);

  if (menuBuilder != null) {
    await menuBuilder(
      context: context,
      controller: controller,
      columnState: state,
      onAction: (action) => applyColumnMenuAction(
        context,
        controller,
        colId,
        action,
        theme: theme,
        filterDialogBuilder: filterDialogBuilder,
      ),
    );
    return;
  }

  // Default: painted overlay menu (no Material dependency)
  if (!context.mounted) return;
  final result = await _showPaintedMenu(context, state);
  if (result == null || !context.mounted) return;
  await applyColumnMenuAction(
    context,
    controller,
    colId,
    result,
    theme: theme,
    filterDialogBuilder: filterDialogBuilder,
  );
}

// ── Default painted overlay menu (no Material) ───────────────────────────────

Future<ColumnMenuAction?> _showPaintedMenu(
  BuildContext context,
  ColumnMenuState state,
) async {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null) return null;

  final overlay = Overlay.of(context);
  final overlayBox = overlay.context.findRenderObject() as RenderBox;
  final position = box.localToGlobal(
    Offset(0, box.size.height),
    ancestor: overlayBox,
  );

  final completer = _MenuCompleter<ColumnMenuAction>();

  final entry = OverlayEntry(
    builder: (ctx) => _PaintedColumnMenu(
      position: position,
      state: state,
      onSelect: (action) {
        completer.complete(action);
      },
      onDismiss: () {
        completer.complete(null);
      },
    ),
  );

  overlay.insert(entry);
  final result = await completer.future;
  entry.remove();
  return result;
}

class _MenuCompleter<T> {
  final _completer = Completer<T?>();

  Future<T?> get future => _completer.future;

  void complete(T? value) {
    if (!_completer.isCompleted) {
      _completer.complete(value);
    }
  }
}

class _PaintedColumnMenu extends StatelessWidget {
  final Offset position;
  final ColumnMenuState state;
  final ValueChanged<ColumnMenuAction> onSelect;
  final VoidCallback onDismiss;

  const _PaintedColumnMenu({
    required this.position,
    required this.state,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
        ColumnMenuAction.sortAsc,
        '↑  Sort ascending',
        state.currentSortDirection == SortDirection.ascending,
      ),
      _MenuItem(
        ColumnMenuAction.sortDesc,
        '↓  Sort descending',
        state.currentSortDirection == SortDirection.descending,
      ),
      _MenuItem(ColumnMenuAction.sortOff, '✕  Clear sort', false),
      _MenuItem.divider(),
      _MenuItem(
        ColumnMenuAction.pinLeft,
        '◧  Pin to left',
        state.frozenSide == FrozenSide.start,
      ),
      _MenuItem(
        ColumnMenuAction.pinRight,
        '◨  Pin to right',
        state.frozenSide == FrozenSide.end,
      ),
      _MenuItem(ColumnMenuAction.pinNone, '◻  Unpin', false),
      _MenuItem.divider(),
      _MenuItem(ColumnMenuAction.hide, '◌  Hide column', false),
      _MenuItem(ColumnMenuAction.fit, '⇔  Resize to fit', false),
      _MenuItem.divider(),
      _MenuItem(
        ColumnMenuAction.filter,
        '▽  Filter…',
        state.hasFilter,
      ),
      if (state.hasFilter)
        _MenuItem(ColumnMenuAction.clearFilter, '△  Clear filter', false,
            isDestructive: true),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onDismiss,
      child: Stack(
        children: [
          Positioned(
            left: position.dx,
            top: position.dy,
            child: _PaintedMenuPanel(
              items: items,
              onSelect: onSelect,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final ColumnMenuAction? action;
  final String label;
  final bool active;
  final bool isDivider;
  final bool isDestructive;

  const _MenuItem(this.action, this.label, this.active,
      {this.isDestructive = false})
      : isDivider = false;

  const _MenuItem.divider()
      : action = null,
        label = '',
        active = false,
        isDivider = true,
        isDestructive = false;
}

class _PaintedMenuPanel extends StatefulWidget {
  final List<_MenuItem> items;
  final ValueChanged<ColumnMenuAction> onSelect;

  const _PaintedMenuPanel({required this.items, required this.onSelect});

  @override
  State<_PaintedMenuPanel> createState() => _PaintedMenuPanelState();
}

class _PaintedMenuPanelState extends State<_PaintedMenuPanel> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < widget.items.length; i++)
                if (widget.items[i].isDivider)
                  Container(
                    height: 1,
                    color: const Color(0xFFE2E8F0),
                  )
                else
                  MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = i),
                    onExit: (_) => setState(() => _hoveredIndex = -1),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final action = widget.items[i].action;
                        if (action != null) widget.onSelect(action);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        color: _hoveredIndex == i
                            ? const Color(0xFFF1F5F9)
                            : null,
                        child: Text(
                          widget.items[i].label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: widget.items[i].active
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: widget.items[i].isDestructive
                                ? const Color(0xFFB91C1C)
                                : widget.items[i].active
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
