import 'package:flutter/material.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

import '_office_log/mock_data.dart';
import '_office_log/models.dart';
import '_office_log/state.dart';

class OfficeTimeLogScreen extends StatefulWidget {
  final GridTheme theme;
  const OfficeTimeLogScreen({super.key, this.theme = GridTheme.mark85});

  @override
  State<OfficeTimeLogScreen> createState() => _OfficeTimeLogScreenState();
}

class _OfficeTimeLogScreenState extends State<OfficeTimeLogScreen> {
  static const _headerRowId = '__header';
  static const _budgetRowId = '__budget';
  static const _totalsRowId = '__totals';
  static const _engineerColId = '__engineer';
  static const _hoursColId = '__hours';
  static const _otColId = '__ot';
  static const _compColId = '__comp';

  late final OfficeLogState _state;
  late GridController _controller;
  late MapGridDataSource _source;
  GridSchema? _schema;
  late CellRendererRegistry _renderers;

  @override
  void initState() {
    super.initState();
    _state = OfficeLogState();
    _renderers = CellRendererRegistry();
    registerDefaultRenderers(_renderers);
    _renderers.registerColumn(_engineerColId, _EngineerInfoRenderer(_state));
    _renderers.registerColumn(_compColId, _CompRenderer(_state));
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
        _budgetRowId,
        ...snap.engineerIds,
        _totalsRowId,
      ],
      colIds: [
        _engineerColId,
        ...snap.columnIds,
        _hoursColId,
        _otColId,
        _compColId,
      ],
    );
    _controller = GridController(schema: _schema!, source: _source);
    _writeAll(snap);
  }

  void _syncFromState() {
    final snap = _state.snapshot;
    final needRebuild = !_listEquals(
          snap.engineerIds,
          _schema!.rows
              .map((r) => r.id)
              .where((id) =>
                  id != _headerRowId &&
                  id != _budgetRowId &&
                  id != _totalsRowId)
              .toList(),
        ) ||
        !_listEquals(
          snap.columnIds,
          _schema!.columns
              .map((c) => c.id)
              .where((id) =>
                  id != _engineerColId &&
                  id != _hoursColId &&
                  id != _otColId &&
                  id != _compColId)
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

  GridSchema _buildSchema(LogSnapshot snap) {
    return GridSchema(
      columns: [
        const ColumnSpec(
          id: _engineerColId,
          header: 'ENGINEER',
          defaultWidth: 240,
          defaultFrozen: FrozenSide.start,
          kind: CellKind.text,
          sortable: false,
        ),
        for (final tid in snap.columnIds)
          ColumnSpec(
            id: tid,
            header: _subTask(tid).code,
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
          id: _compColId,
          header: 'COMP HRS',
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
          id: _budgetRowId,
          defaultHeight: 38,
          defaultFrozen: FrozenSide.start,
          defaultFreezePriority: 1,
        ),
        for (final eid in snap.engineerIds)
          RowSpec(id: eid, defaultHeight: 44),
        const RowSpec(
          id: _totalsRowId,
          defaultHeight: 44,
          defaultFrozen: FrozenSide.end,
        ),
      ],
    );
  }

  void _writeAll(LogSnapshot snap) {
    for (final eid in snap.engineerIds) {
      final row = snap.cells[eid];
      for (final tid in snap.columnIds) {
        final v = row?[tid] ?? 0;
        _source.setValue(
          eid,
          tid,
          v == 0 ? const EmptyCell() : NumberCell(v),
        );
      }
      final hours = _state.rowHours(eid);
      final ot = _state.rowOt(eid);
      _source.setValue(
          eid, _hoursColId, hours == 0 ? const EmptyCell() : NumberCell(hours));
      _source.setValue(
          eid, _otColId, ot == 0 ? const EmptyCell() : NumberCell(ot));
    }
    for (final tid in snap.columnIds) {
      final q = snap.budgets[tid] ?? 0;
      _source.setValue(
        _budgetRowId,
        tid,
        q == 0 ? const EmptyCell() : NumberCell(q),
      );
    }
    for (final tid in snap.columnIds) {
      final t = _state.columnTotal(tid);
      _source.setValue(
        _totalsRowId,
        tid,
        t == 0 ? const EmptyCell() : NumberCell(t),
      );
    }
    _source.setValue(_totalsRowId, _hoursColId, NumberCell(_state.grandHours));
    _source.setValue(_totalsRowId, _otColId, NumberCell(_state.grandOt));
  }

  SubTask _subTask(String id) => kAllSubTasks.firstWhere((c) => c.id == id);
  Engineer _engineer(String id) => kAllEngineers.firstWhere((w) => w.id == id);

  void _onCommit(RowId rowId, ColId colId, CellValue value) {
    if (rowId == _budgetRowId) {
      final v = value is NumberCell ? value.value : 0.0;
      _state.setBudget(colId, v);
      return;
    }
    if (rowId == _totalsRowId) return;
    if (colId == _hoursColId || colId == _otColId) return;
    if (colId == _engineerColId) return;
    if (colId == _compColId) return;
    final v = value is NumberCell ? value.value : 0.0;
    _state.setCell(rowId, colId, v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Toolbar(state: _state),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: UltimateTable(
              controller: _controller,
              theme: widget.theme,
              renderers: _renderers,
              widgetColumns: const {_engineerColId, _compColId},
              cellWidgetBuilder: _buildBodyOverlay,
              onCellCommit: _onCommit,
            ),
          ),
        ),
        _BottomToolbar(
          state: _state,
          onAddEngineer: _showAddEngineer,
          onAddSubTask: _showAddSubTask,
        ),
      ],
    );
  }

  Widget _buildBodyOverlay(
    BuildContext context,
    RowId rowId,
    ColId colId,
    CellValue value,
  ) {
    if (colId == _engineerColId) {
      final e = _engineer(rowId);
      final absent = _state.snapshot.absent[rowId]?.absent ?? false;
      return _EngineerInfoTile(
        engineer: e,
        absent: absent,
        onAbsent: (v) => _state.setAbsent(rowId, v),
        onRemove: () => _state.removeEngineer(rowId),
      );
    }
    if (colId == _compColId) {
      final c = _state.snapshot.comp[rowId];
      final absent = _state.snapshot.absent[rowId]?.absent ?? false;
      return _CompTile(
        comp: c,
        disabled: absent,
        onGiven: (v) => _state.setCompGiven(rowId, v),
        onAmount: (v) => _state.setCompAmount(rowId, v),
      );
    }
    return const SizedBox.shrink();
  }

  void _showAddEngineer() {
    final available = kAllEngineers
        .where((e) => !_state.engineerIds.contains(e.id))
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => _PickList<Engineer>(
        title: 'Add engineer',
        items: available,
        renderTile: (e) => ListTile(
          dense: true,
          title: Text(e.displayName,
              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
          subtitle: Text(
            '${e.role} · #${e.employeeNumber}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          onTap: () {
            _state.addEngineer(e.id);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _showAddSubTask() {
    final available =
        kAllSubTasks.where((t) => !_state.columnIds.contains(t.id)).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => _PickList<SubTask>(
        title: 'Add sub-task',
        items: available,
        renderTile: (t) => ListTile(
          dense: true,
          title: Text.rich(TextSpan(children: [
            TextSpan(
                text: t.code,
                style: const TextStyle(
                    fontFamily: 'Menlo',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF0F172A))),
            const TextSpan(text: '  '),
            TextSpan(
                text: t.name,
                style:
                    const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
          ])),
          subtitle: Text(
            'Project ${t.projectCode ?? "-"} · ${t.unitOfMeasure ?? "-"}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          onTap: () {
            _state.addColumn(t.id);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Renderers (header row injected as a top-frozen synthetic row whose cells
// each render their column header label).
// ---------------------------------------------------------------------------

class _HeaderAwareNumberRenderer extends CellRenderer {
  const _HeaderAwareNumberRenderer();
  static const _fallback = NumberCellRenderer();
  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    if (ctx.rowId == _OfficeTimeLogScreenState._headerRowId) {
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
    if (ctx.rowId == _OfficeTimeLogScreenState._headerRowId) {
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
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
          letterSpacing: 1,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _EngineerInfoRenderer extends CellRenderer {
  final OfficeLogState state;
  const _EngineerInfoRenderer(this.state);

  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    if (ctx.rowId == _OfficeTimeLogScreenState._headerRowId) {
      return const _HeaderCell(label: 'ENGINEER');
    }
    if (ctx.rowId == _OfficeTimeLogScreenState._budgetRowId) {
      return Container(
        color: const Color(0xFFECFDF5),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: const Text(
          'BUDGET HRS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF047857),
            letterSpacing: 1,
          ),
          textAlign: TextAlign.right,
        ),
      );
    }
    if (ctx.rowId == _OfficeTimeLogScreenState._totalsRowId) {
      return Container(
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: const Text(
          'SUB-TASK TOTALS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 1,
          ),
          textAlign: TextAlign.right,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _CompRenderer extends CellRenderer {
  final OfficeLogState state;
  const _CompRenderer(this.state);

  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    if (ctx.rowId == _OfficeTimeLogScreenState._headerRowId) {
      return const _HeaderCell(label: 'COMP HRS');
    }
    if (ctx.rowId == _OfficeTimeLogScreenState._budgetRowId) {
      return Container(color: const Color(0xFFECFDF5));
    }
    if (ctx.rowId == _OfficeTimeLogScreenState._totalsRowId) {
      return Container(
        color: const Color(0xFFECFDF5),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          state.grandComp == 0 ? '' : state.grandComp.toStringAsFixed(2),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF047857),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _EngineerInfoTile extends StatelessWidget {
  final Engineer engineer;
  final bool absent;
  final void Function(bool) onAbsent;
  final VoidCallback onRemove;

  const _EngineerInfoTile({
    required this.engineer,
    required this.absent,
    required this.onAbsent,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bg = absent ? const Color(0xFFF1F5F9) : Colors.white;
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
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: const Icon(Icons.close,
                  size: 12, color: Color(0xFF64748B)),
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
              activeColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  engineer.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: absent ? TextDecoration.lineThrough : null,
                    color: absent
                        ? const Color(0xFF64748B)
                        : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${engineer.role} · #${engineer.employeeNumber}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
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

class _CompTile extends StatelessWidget {
  final CompHours? comp;
  final bool disabled;
  final void Function(bool) onGiven;
  final void Function(double?) onAmount;
  const _CompTile({
    required this.comp,
    required this.disabled,
    required this.onGiven,
    required this.onAmount,
  });

  @override
  Widget build(BuildContext context) {
    final given = comp?.given ?? false;
    return Container(
      color: const Color(0xFFECFDF5),
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
              activeColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: given && !disabled
                ? _CompAmountField(
                    initial: comp?.amount,
                    onChanged: (v) => onAmount(v == 0 ? null : v),
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      given ? '–' : '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompAmountField extends StatefulWidget {
  final double? initial;
  final ValueChanged<double> onChanged;
  const _CompAmountField({required this.initial, required this.onChanged});

  @override
  State<_CompAmountField> createState() => _CompAmountFieldState();
}

class _CompAmountFieldState extends State<_CompAmountField> {
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

class _Toolbar extends StatelessWidget {
  final OfficeLogState state;
  const _Toolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (_, __) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            const Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Office Time Log — Sprint 24',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '· May 17, 2026',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
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
          ],
        ),
      ),
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  final OfficeLogState state;
  final VoidCallback onAddEngineer;
  final VoidCallback onAddSubTask;
  const _BottomToolbar({
    required this.state,
    required this.onAddEngineer,
    required this.onAddSubTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onAddEngineer,
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Add engineer'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32)),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onAddSubTask,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add sub-task'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: state,
              builder: (_, __) => Text(
                'Total hours: ${state.grandHours.toStringAsFixed(1)}  ·  '
                'OT: ${state.grandOt.toStringAsFixed(1)}  ·  '
                'Comp: ${state.grandComp.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
  const _PickList({
    required this.title,
    required this.items,
    required this.renderTile,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A))),
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
                child: Text('Nothing left to add',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (_, i) => renderTile(items[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
