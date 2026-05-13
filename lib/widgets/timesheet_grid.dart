import 'package:flutter/material.dart';
import 'package:ultimate_table/ultimate_table.dart';

import '../data/mock_data.dart';
import '../models/grid_models.dart';
import '../state/grid_state.dart';
import '../theme/mark85_theme.dart';

/// Mark 85 timesheet rebuilt on top of [UltimateTable].
///
/// Schema:
///   rows    = [QTY row (top-frozen), …workerIds…, TOTALS row (bottom-frozen)]
///   columns = [worker (left-frozen, widget-rendered),
///              …costCodeIds…,
///              hours / ot / perDiem (right-frozen — perDiem widget-rendered)]
///
/// `GridState` keeps undo/redo and the hours/OT/totals derivation; this
/// widget mirrors snapshots into a [MapGridDataSource] on every change.
class TimesheetGrid extends StatefulWidget {
  const TimesheetGrid({super.key});

  @override
  State<TimesheetGrid> createState() => _TimesheetGridState();
}

class _TimesheetGridState extends State<TimesheetGrid> {
  static const _headerRowId = '__header';
  static const _qtyRowId = '__qty';
  static const _totalsRowId = '__totals';
  static const _workerColId = '__worker';
  static const _hoursColId = '__hours';
  static const _otColId = '__ot';
  static const _perDiemColId = '__perdiem';

  late final GridState _state;
  late GridController _controller;
  late MapGridDataSource _source;
  GridSchema? _schema;
  late CellRendererRegistry _renderers;

  @override
  void initState() {
    super.initState();
    _state = GridState();
    _renderers = CellRendererRegistry();
    registerDefaultRenderers(_renderers);
    _renderers.registerColumn(_workerColId, _WorkerInfoRenderer(_state));
    _renderers.registerColumn(_perDiemColId, _PerDiemRenderer(_state));
    // Header row is implemented as a top-frozen "__header" row — every
    // cell renders its column's header text. Falls through to per-column
    // overrides above for the worker / per-diem columns.
    _renderers.registerKind(CellKind.number, _HeaderAwareNumberRenderer());
    _renderers.registerKind(CellKind.text, _HeaderAwareTextRenderer());
    _state.addListener(_syncFromState);
    _rebuildAll();
  }

  @override
  void dispose() {
    _state.removeListener(_syncFromState);
    _state.dispose();
    _controller.dispose();
    _source.dispose();
    super.dispose();
  }

  void _rebuildAll() {
    final snap = _state.snapshot;
    _schema = _buildSchema(snap);
    _source = MapGridDataSource(
      rowIds: [
        _headerRowId,
        _qtyRowId,
        ...snap.workerIds,
        _totalsRowId,
      ],
      colIds: [
        _workerColId,
        ...snap.columnIds,
        _hoursColId,
        _otColId,
        _perDiemColId,
      ],
    );
    _controller = GridController(schema: _schema!, source: _source);
    _writeAll(snap);
  }

  void _syncFromState() {
    final snap = _state.snapshot;
    // If row/column set changed, rebuild schema + controller wholesale.
    final needRebuild = !_listEquals(
          snap.workerIds,
          _schema!.rows
              .map((r) => r.id)
              .where((id) =>
                  id != _headerRowId &&
                  id != _qtyRowId &&
                  id != _totalsRowId)
              .toList(),
        ) ||
        !_listEquals(
          snap.columnIds,
          _schema!.columns
              .map((c) => c.id)
              .where((id) =>
                  id != _workerColId &&
                  id != _hoursColId &&
                  id != _otColId &&
                  id != _perDiemColId)
              .toList(),
        );
    if (needRebuild) {
      _controller.dispose();
      _source.dispose();
      _rebuildAll();
    } else {
      _writeAll(snap);
    }
    if (mounted) setState(() {});
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  GridSchema _buildSchema(GridSnapshot snap) {
    return GridSchema(
      columns: [
        const ColumnSpec(
          id: _workerColId,
          header: 'CREW',
          defaultWidth: 240,
          defaultFrozen: FrozenSide.start,
          kind: CellKind.text,
          sortable: false,
        ),
        for (final ccId in snap.columnIds)
          ColumnSpec(
            id: ccId,
            header: _costCode(ccId).code,
            defaultWidth: 130,
            kind: CellKind.number,
          ),
        const ColumnSpec(
          id: _hoursColId,
          header: 'HOURS',
          defaultWidth: 80,
          defaultFrozen: FrozenSide.end,
          defaultFreezePriority: 0,
          kind: CellKind.number,
        ),
        const ColumnSpec(
          id: _otColId,
          header: 'OT',
          defaultWidth: 70,
          defaultFrozen: FrozenSide.end,
          defaultFreezePriority: 1,
          kind: CellKind.number,
        ),
        const ColumnSpec(
          id: _perDiemColId,
          header: 'PER DIEM',
          defaultWidth: 110,
          defaultFrozen: FrozenSide.end,
          defaultFreezePriority: 2,
          kind: CellKind.text,
          sortable: false,
        ),
      ],
      rows: [
        const RowSpec(
          id: _headerRowId,
          defaultHeight: 44,
          defaultFrozen: FrozenSide.start,
          defaultFreezePriority: 0,
        ),
        const RowSpec(
          id: _qtyRowId,
          defaultHeight: 38,
          defaultFrozen: FrozenSide.start,
          defaultFreezePriority: 1,
        ),
        for (final wid in snap.workerIds)
          RowSpec(id: wid, defaultHeight: 44),
        const RowSpec(
          id: _totalsRowId,
          defaultHeight: 44,
          defaultFrozen: FrozenSide.end,
        ),
      ],
    );
  }

  void _writeAll(GridSnapshot snap) {
    // Body cells.
    for (final wid in snap.workerIds) {
      final row = snap.cells[wid];
      for (final ccId in snap.columnIds) {
        final v = row?[ccId] ?? 0;
        _source.setValue(
          wid,
          ccId,
          v == 0 ? const EmptyCell() : NumberCell(v),
        );
      }
      // Hours / OT derived.
      final hours = _state.rowHours(wid);
      final ot = _state.rowOt(wid);
      _source.setValue(
          wid, _hoursColId, hours == 0 ? const EmptyCell() : NumberCell(hours));
      _source.setValue(
          wid, _otColId, ot == 0 ? const EmptyCell() : NumberCell(ot));
    }
    // Quantity row.
    for (final ccId in snap.columnIds) {
      final q = snap.quantities[ccId] ?? 0;
      _source.setValue(
        _qtyRowId,
        ccId,
        q == 0 ? const EmptyCell() : NumberCell(q),
      );
    }
    // Totals row.
    for (final ccId in snap.columnIds) {
      final t = _state.columnTotal(ccId);
      _source.setValue(
        _totalsRowId,
        ccId,
        t == 0 ? const EmptyCell() : NumberCell(t),
      );
    }
    _source.setValue(_totalsRowId, _hoursColId, NumberCell(_state.grandHours));
    _source.setValue(_totalsRowId, _otColId, NumberCell(_state.grandOt));
  }

  CostCode _costCode(String id) => kAllCostCodes.firstWhere((c) => c.id == id);

  Worker _worker(String id) => kAllWorkers.firstWhere((w) => w.id == id);

  void _onCommit(RowId rowId, ColId colId, CellValue value) {
    if (rowId == _qtyRowId) {
      final v = value is NumberCell ? value.value : 0.0;
      _state.setQuantity(colId, v);
      return;
    }
    if (rowId == _totalsRowId) return; // derived
    if (colId == _hoursColId || colId == _otColId) return; // derived
    if (colId == _workerColId) return; // widget handles edits
    if (colId == _perDiemColId) return; // widget handles edits
    // body cell:
    final v = value is NumberCell ? value.value : 0.0;
    _state.setCell(rowId, colId, v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: M85Colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Toolbar(state: _state),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: M85Colors.borderColor),
                    right: BorderSide(color: M85Colors.borderColor),
                    top: BorderSide(color: M85Colors.borderColor),
                    bottom: BorderSide(color: M85Colors.borderColor),
                  ),
                  color: M85Colors.backgroundStrong,
                ),
                child: UltimateTable(
                  controller: _controller,
                  renderers: _renderers,
                  widgetColumns: const {_workerColId, _perDiemColId},
                  cellWidgetBuilder: _buildBodyOverlay,
                  onCellCommit: _onCommit,
                ),
              ),
            ),
            _BottomToolbar(state: _state, onAddCrew: _showAddCrew, onAddCostCode: _showAddCostCode),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyOverlay(
    BuildContext context,
    RowId rowId,
    ColId colId,
    CellValue value,
  ) {
    if (colId == _workerColId) {
      final w = _worker(rowId);
      final absent = _state.snapshot.absent[rowId]?.absent ?? false;
      return _WorkerInfoTile(
        worker: w,
        absent: absent,
        onAbsent: (v) => _state.setAbsent(rowId, v),
        onRemove: () => _state.removeWorker(rowId),
      );
    }
    if (colId == _perDiemColId) {
      final pd = _state.snapshot.perDiem[rowId];
      final absent = _state.snapshot.absent[rowId]?.absent ?? false;
      return _PerDiemTile(
        pd: pd,
        disabled: absent,
        onGiven: (v) => _state.setPerDiemGiven(rowId, v),
        onAmount: (v) => _state.setPerDiemAmount(rowId, v),
      );
    }
    return const SizedBox.shrink();
  }

  void _showAddCrew() {
    final available = kAllWorkers
        .where((w) => !_state.workerIds.contains(w.id))
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: M85Colors.backgroundStrong,
      builder: (ctx) => _PickList<Worker>(
        title: 'Add crew',
        items: available,
        renderTile: (w) => ListTile(
          dense: true,
          title: Text(w.displayName, style: M85Text.body),
          subtitle: Text('${w.classification} · #${w.employeeNumber}',
              style: M85Text.bodyMuted),
          onTap: () {
            _state.addWorker(w.id);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _showAddCostCode() {
    final available = kAllCostCodes
        .where((c) => !_state.columnIds.contains(c.id))
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: M85Colors.backgroundStrong,
      builder: (ctx) => _PickList<CostCode>(
        title: 'Add cost code',
        items: available,
        renderTile: (c) => ListTile(
          dense: true,
          title: Text.rich(TextSpan(children: [
            TextSpan(text: c.code, style: M85Text.code),
            const TextSpan(text: '  '),
            TextSpan(text: c.name, style: M85Text.body),
          ])),
          subtitle: Text('Phase ${c.phaseCode ?? "-"} · ${c.unitOfMeasure ?? "-"}',
              style: M85Text.bodyMuted),
          onTap: () {
            _state.addColumn(c.id);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom renderers + widgets
// ---------------------------------------------------------------------------

/// Number-cell renderer that special-cases the schema's synthetic
/// `__header` row by displaying the column's header label instead of the
/// stored value.
class _HeaderAwareNumberRenderer extends CellRenderer {
  const _HeaderAwareNumberRenderer();
  static const _fallback = NumberCellRenderer();
  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    if (ctx.rowId == _TimesheetGridState._headerRowId) {
      return _HeaderCell(label: ctx.column.header);
    }
    return _fallback.build(context, value, ctx);
  }
}

class _HeaderAwareTextRenderer extends CellRenderer {
  const _HeaderAwareTextRenderer();
  static const _fallback = TextCellRenderer();
  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    if (ctx.rowId == _TimesheetGridState._headerRowId) {
      return _HeaderCell(label: ctx.column.header);
    }
    return _fallback.build(context, value, ctx);
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: M85Colors.backgroundHover,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: M85Text.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _WorkerInfoRenderer extends CellRenderer {
  final GridState state;
  const _WorkerInfoRenderer(this.state);

  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    if (ctx.rowId == _TimesheetGridState._headerRowId) {
      return const _HeaderCell(label: 'CREW');
    }
    // Used for top/bottom frozen rows (QTY label + TOTALS label).
    if (ctx.rowId == _TimesheetGridState._qtyRowId) {
      return Container(
        color: M85Colors.successSoft,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: const Text(
          'QTY TO CLAIM',
          style: M85Text.label,
          textAlign: TextAlign.right,
        ),
      );
    }
    if (ctx.rowId == _TimesheetGridState._totalsRowId) {
      return Container(
        color: M85Colors.backgroundHover,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: const Text(
          'COST CODE TOTALS',
          style: M85Text.label,
          textAlign: TextAlign.right,
        ),
      );
    }
    // Default for any body rows that fall through here (shouldn't normally).
    return const SizedBox.shrink();
  }
}

class _PerDiemRenderer extends CellRenderer {
  final GridState state;
  const _PerDiemRenderer(this.state);

  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    if (ctx.rowId == _TimesheetGridState._headerRowId) {
      return const _HeaderCell(label: 'PER DIEM');
    }
    if (ctx.rowId == _TimesheetGridState._qtyRowId) {
      return Container(color: M85Colors.successSoft);
    }
    if (ctx.rowId == _TimesheetGridState._totalsRowId) {
      return Container(
        color: M85Colors.successSoft,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          state.grandPerDiem == 0 ? '' : state.grandPerDiem.toStringAsFixed(2),
          style: M85Text.numBold.copyWith(color: const Color(0xFF047857)),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _WorkerInfoTile extends StatelessWidget {
  final Worker worker;
  final bool absent;
  final void Function(bool) onAbsent;
  final VoidCallback onRemove;

  const _WorkerInfoTile({
    required this.worker,
    required this.absent,
    required this.onAbsent,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bg = absent ? M85Colors.backgroundHover : M85Colors.backgroundStrong;
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(color: M85Colors.borderColor),
                borderRadius: BorderRadius.circular(4),
                color: M85Colors.backgroundStrong,
              ),
              child: const Icon(Icons.close, size: 12, color: M85Colors.colorMuted),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: absent,
              onChanged: (v) => onAbsent(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              activeColor: M85Colors.danger,
              side: const BorderSide(color: M85Colors.borderColorHover),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  worker.displayName,
                  style: M85Text.body.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: absent ? TextDecoration.lineThrough : null,
                    color: absent ? M85Colors.colorMuted : M85Colors.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${worker.classification} · #${worker.employeeNumber}',
                  style: M85Text.bodyMuted.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerDiemTile extends StatelessWidget {
  final PerDiem? pd;
  final bool disabled;
  final void Function(bool) onGiven;
  final void Function(double?) onAmount;
  const _PerDiemTile({
    required this.pd,
    required this.disabled,
    required this.onGiven,
    required this.onAmount,
  });

  @override
  Widget build(BuildContext context) {
    final given = pd?.given ?? false;
    return Container(
      color: M85Colors.successSoft,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: given,
              onChanged: disabled ? null : (v) => onGiven(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              activeColor: M85Colors.success,
              side: const BorderSide(color: M85Colors.borderColorHover),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: given && !disabled
                ? _PerDiemAmountField(
                    initial: pd?.amount,
                    onChanged: (v) => onAmount(v == 0 ? null : v),
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      given ? '–' : '',
                      style: M85Text.num.copyWith(color: M85Colors.colorMuted),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PerDiemAmountField extends StatefulWidget {
  final double? initial;
  final ValueChanged<double> onChanged;
  const _PerDiemAmountField({required this.initial, required this.onChanged});

  @override
  State<_PerDiemAmountField> createState() => _PerDiemAmountFieldState();
}

class _PerDiemAmountFieldState extends State<_PerDiemAmountField> {
  late final TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initial == null ? '' : widget.initial!.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    final v = double.tryParse(_ctrl.text);
    if (v == null) return;
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      style: M85Text.num,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onSubmitted: (_) => _commit(),
      onTapOutside: (_) => _commit(),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbars + picker (kept simple — most of this was preserved from the
// pre-port grid_screen.dart and stripped down for the new layout).
// ---------------------------------------------------------------------------

class _Toolbar extends StatelessWidget {
  final GridState state;
  const _Toolbar({required this.state});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (_, __) => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: const BoxDecoration(
          color: M85Colors.backgroundStrong,
          border: Border(bottom: BorderSide(color: M85Colors.borderColor)),
        ),
        child: Row(
          children: [
            const Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Timesheet — Lakeside Phase 2',
                      style: M85Text.h1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('· May 8, 2026', style: M85Text.bodyMuted),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Undo',
              onPressed: state.canUndo ? state.undo : null,
              icon: const Icon(Icons.undo, size: 18),
            ),
            IconButton(
              tooltip: 'Redo',
              onPressed: state.canRedo ? state.redo : null,
              icon: const Icon(Icons.redo, size: 18),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: M85Colors.primary,
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  final GridState state;
  final VoidCallback onAddCrew;
  final VoidCallback onAddCostCode;
  const _BottomToolbar({
    required this.state,
    required this.onAddCrew,
    required this.onAddCostCode,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: M85Colors.backgroundStrong,
        border: Border(top: BorderSide(color: M85Colors.borderColor)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onAddCrew,
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Add crew'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32)),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onAddCostCode,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add cost code'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: state,
              builder: (_, __) => Text(
                'Grand hours: ${state.grandHours.toStringAsFixed(1)}  ·  '
                'OT: ${state.grandOt.toStringAsFixed(1)}  ·  '
                'Per diem: ${state.grandPerDiem.toStringAsFixed(2)}',
                style: M85Text.bodyMuted,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickList<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final Widget Function(T) renderTile;
  const _PickList({required this.title, required this.items, required this.renderTile});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: M85Colors.borderColor)),
              ),
              child: Row(
                children: [
                  Text(title, style: M85Text.h1),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nothing left to add', style: M85Text.bodyMuted),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: M85Colors.borderColor),
                  itemBuilder: (_, i) => renderTile(items[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
