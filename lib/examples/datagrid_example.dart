import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

import 'shared.dart';

/// Records-as-rows datagrid. 200-row mock inventory, full feature wiring:
/// search, column popup menu (sort / filter / pin / hide / fit), drag-to-
/// resize, drag-to-reorder, multi-range body selection, Cmd/Ctrl+C copy,
/// async / sync data-source toggle.
class DatagridExample extends StatefulWidget {
  const DatagridExample({super.key});

  @override
  State<DatagridExample> createState() => _DatagridExampleState();
}

class _DatagridExampleState extends State<DatagridExample> {
  static const _columns = [
    ColumnSpec(
      id: 'sku',
      header: 'SKU',
      defaultWidth: 110,
      defaultFrozen: FrozenSide.start,
    ),
    ColumnSpec(id: 'name', header: 'Product', defaultWidth: 220),
    ColumnSpec(id: 'category', header: 'Category', defaultWidth: 130),
    ColumnSpec(
      id: 'stock',
      header: 'Stock',
      defaultWidth: 90,
      kind: CellKind.number,
    ),
    ColumnSpec(
      id: 'price',
      header: 'Price',
      defaultWidth: 100,
      kind: CellKind.number,
    ),
    ColumnSpec(
      id: 'cost',
      header: 'Cost',
      defaultWidth: 100,
      kind: CellKind.number,
    ),
    ColumnSpec(
      id: 'margin',
      header: 'Margin %',
      defaultWidth: 100,
      kind: CellKind.number,
      defaultFrozen: FrozenSide.end,
    ),
    ColumnSpec(
      id: 'active',
      header: 'Active',
      defaultWidth: 80,
      kind: CellKind.bool_,
    ),
    ColumnSpec(
      id: 'restock',
      header: 'Restock',
      defaultWidth: 130,
      kind: CellKind.date,
    ),
    ColumnSpec(id: 'supplier', header: 'Supplier', defaultWidth: 180),
  ];

  late GridSchema _schema;
  GridDataSource? _source;
  late GridController _controller;
  final _searchCtrl = TextEditingController();
  bool _async = false;
  int _asyncLoads = 0;
  String? _lastCopy;

  @override
  void initState() {
    super.initState();
    _schema = GridSchema(
      columns: _columns,
      rows: [
        for (var i = 0; i < 200; i++)
          RowSpec(id: 'p_${i.toString().padLeft(3, '0')}'),
      ],
    );
    _build(async: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_source is ChangeNotifier) (_source as ChangeNotifier).dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _build({required bool async}) {
    if (_source is ChangeNotifier) (_source as ChangeNotifier).dispose();
    final rowIds = [for (final r in _schema.rows) r.id];
    final colIds = [for (final c in _schema.columns) c.id];
    if (async) {
      _source = AsyncGridDataSource(
        rowIds: rowIds,
        colIds: colIds,
        pageSize: 25,
        fetchRange: (start, end) async {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          if (!mounted) {
            return AsyncPage(
                rowIds: rowIds.sublist(start, end), cells: const {});
          }
          setState(() => _asyncLoads++);
          final cells = <RowId, Map<ColId, CellValue>>{};
          for (var i = start; i < end; i++) {
            cells[rowIds[i]] = _mockCellsFor(i);
          }
          return AsyncPage(rowIds: rowIds.sublist(start, end), cells: cells);
        },
      );
    } else {
      final src = MapGridDataSource(rowIds: rowIds, colIds: colIds);
      for (var i = 0; i < rowIds.length; i++) {
        final c = _mockCellsFor(i);
        c.forEach((k, v) => src.setValue(rowIds[i], k, v));
      }
      _source = src;
    }
    _controller = GridController(schema: _schema, source: _source!);
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..addListener(_onSearchChanged);
    setState(() {});
  }

  void _onSearchChanged() => _controller.setSearchQuery(_searchCtrl.text);

  Map<ColId, CellValue> _mockCellsFor(int i) {
    const cats = ['Cable', 'Adapter', 'Battery', 'Sensor', 'Module'];
    const suppliers = [
      'Acme Corp',
      'Globex',
      'Initech',
      'Soylent',
      'Umbrella'
    ];
    final cat = cats[i % cats.length];
    final sup = suppliers[(i * 7) % suppliers.length];
    final price = 12.0 + (i * 3 % 47) + (i % 5) * 0.25;
    final cost = price * (0.45 + (i % 7) * 0.03);
    final margin = ((price - cost) / price) * 100;
    final stock = (i * 13 % 200);
    final active = (i % 9) != 3;
    return {
      'sku': TextCell('SKU-${(i + 1001).toString().padLeft(4, '0')}'),
      'name': TextCell('$cat ${String.fromCharCode(65 + (i % 26))}${i % 100}'),
      'category': TextCell(cat),
      'stock': NumberCell(stock.toDouble()),
      'price': NumberCell(double.parse(price.toStringAsFixed(2))),
      'cost': NumberCell(double.parse(cost.toStringAsFixed(2))),
      'margin': NumberCell(double.parse(margin.toStringAsFixed(1))),
      'active': BoolCell(active),
      'restock': DateCell(
          DateTime(2026, 5, 12).add(Duration(days: (i * 5) % 90))),
      'supplier': TextCell(sup),
    };
  }

  Future<void> _copy() async {
    if (_controller.selection.isEmpty) {
      _controller.selectAll();
    }
    final tsv = GridClipboard.selectionAsTsv(_controller);
    await Clipboard.setData(ClipboardData(text: tsv));
    if (!mounted) return;
    setState(() {
      _lastCopy = tsv.length > 80 ? '${tsv.substring(0, 80)}…' : tsv;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolbar(),
          const SizedBox(height: 8),
          const HelpBanner(
            text:
                'Click a column header for the sort/filter/pin/hide/fit menu. '
                'Drag the right edge to resize. Drag in the body to '
                'multi-select; Cmd/Ctrl-click for non-contiguous; '
                'Cmd/Ctrl+C copies as TSV.',
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: UltimateTable(
                controller: _controller,
                headerBuilder: (ctx, colId) =>
                    HeaderLabel(controller: _controller, colId: colId),
                onHeaderTap: (cellCtx, colId) => showUltimateColumnMenu(
                  context: cellCtx,
                  controller: _controller,
                  colId: colId,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _StatusBar(
            controller: _controller,
            onCopy: _copy,
            lastCopy: _lastCopy,
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        UltimateSearchField(controller: _controller),
        TextButton.icon(
          onPressed: () {
            for (final id in _controller.hiddenColumns.toList()) {
              _controller.showColumn(id);
            }
          },
          icon: const Icon(Icons.visibility_outlined, size: 14),
          label: Text(
              'Show hidden (${_controller.hiddenColumns.length})'),
        ),
        FilterChip(
          label: Text(_async
              ? 'Async ($_asyncLoads pages)'
              : 'Sync (instant)'),
          selected: _async,
          onSelected: (v) => setState(() {
            _async = v;
            _build(async: v);
          }),
          avatar: Icon(
            _async ? Icons.cloud_download : Icons.bolt,
            size: 14,
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatefulWidget {
  final GridController controller;
  final VoidCallback onCopy;
  final String? lastCopy;
  const _StatusBar({
    required this.controller,
    required this.onCopy,
    required this.lastCopy,
  });
  @override
  State<_StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<_StatusBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_bump);
  }

  @override
  void didUpdateWidget(_StatusBar old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      old.controller.removeListener(_bump);
      widget.controller.addListener(_bump);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_bump);
    super.dispose();
  }

  void _bump() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final sel = widget.controller.selection;
    final view = widget.controller.pipelineResult.viewRowIndices.length;
    final ranges = sel.ranges.length;
    final desc = sel.isEmpty
        ? 'No selection'
        : '$ranges range${ranges == 1 ? "" : "s"}, '
            'active=${_describe(sel.activeRange!)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          Text('$view rows  ·  $desc',
              style: const TextStyle(fontSize: 12)),
          if (widget.lastCopy != null)
            Text(
              'Copied: ${widget.lastCopy}',
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          TextButton.icon(
            onPressed: widget.onCopy,
            icon: const Icon(Icons.copy, size: 14),
            label: const Text('Copy selection'),
            style: TextButton.styleFrom(minimumSize: const Size(0, 28)),
          ),
        ],
      ),
    );
  }

  String _describe(SelectionRange r) {
    if (r.isWholeRow) return 'row ${r.anchorRowIndex}';
    if (r.isWholeColumn) return 'col ${r.anchorColIndex}';
    return '(${r.topRow},${r.leftCol})→(${r.bottomRow},${r.rightCol})';
  }
}
