import 'package:flutter/material.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

import '_shared.dart';

class SearchFiltersScreen extends StatefulWidget {
  final GridTheme theme;
  const SearchFiltersScreen({super.key, this.theme = GridTheme.mark85});

  @override
  State<SearchFiltersScreen> createState() => _SearchFiltersScreenState();
}

class _SearchFiltersScreenState extends State<SearchFiltersScreen> {
  static const _columns = [
    ColumnSpec(id: 'sku', header: 'SKU', defaultWidth: 110, defaultFrozen: FrozenSide.start),
    ColumnSpec(id: 'name', header: 'Product', defaultWidth: 220),
    ColumnSpec(id: 'category', header: 'Category', defaultWidth: 130),
    ColumnSpec(id: 'stock', header: 'Stock', defaultWidth: 90, kind: CellKind.number),
    ColumnSpec(id: 'price', header: 'Price', defaultWidth: 100, kind: CellKind.number),
    ColumnSpec(id: 'active', header: 'Active', defaultWidth: 80, kind: CellKind.bool_),
    ColumnSpec(id: 'restock', header: 'Restock', defaultWidth: 130, kind: CellKind.date),
    ColumnSpec(id: 'supplier', header: 'Supplier', defaultWidth: 180),
  ];

  late final MapGridDataSource _source;
  late final GridController _controller;

  @override
  void initState() {
    super.initState();
    final schema = GridSchema(
      columns: _columns,
      rows: [for (var i = 0; i < 300; i++) RowSpec(id: 'p_${i.toString().padLeft(3, '0')}')],
    );
    _source = MapGridDataSource(rowIds: [for (final r in schema.rows) r.id], colIds: [for (final c in schema.columns) c.id]);
    const cats = ['Cable', 'Adapter', 'Battery', 'Sensor', 'Module'];
    const suppliers = ['Acme Corp', 'Globex', 'Initech', 'Soylent', 'Umbrella'];
    for (var i = 0; i < schema.rows.length; i++) {
      final id = schema.rows[i].id;
      final cat = cats[i % cats.length];
      final sup = suppliers[(i * 7) % suppliers.length];
      final price = 12.0 + (i * 3 % 47) + (i % 5) * 0.25;
      _source.setValue(id, 'sku', TextCell('SKU-${(i + 1001).toString().padLeft(4, '0')}'));
      _source.setValue(id, 'name', TextCell('$cat ${String.fromCharCode(65 + (i % 26))}${i % 100}'));
      _source.setValue(id, 'category', TextCell(cat));
      _source.setValue(id, 'stock', NumberCell((i * 13 % 200).toDouble()));
      _source.setValue(id, 'price', NumberCell(double.parse(price.toStringAsFixed(2))));
      _source.setValue(id, 'active', BoolCell((i % 9) != 3));
      _source.setValue(id, 'restock', DateCell(DateTime(2026, 5, 12).add(Duration(days: (i * 5) % 90))));
      _source.setValue(id, 'supplier', TextCell(sup));
    }
    _controller = GridController(schema: schema, source: _source);
  }

  @override
  void dispose() {
    _controller.dispose();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
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
                label: Text('Show hidden (${_controller.hiddenColumns.length})'),
              ),
              TextButton.icon(
                onPressed: () {
                  for (final id in _controller.filters.keys.toList()) {
                    _controller.setFilter(id, null);
                  }
                  _controller.setSortKeys(const []);
                  _controller.setSearchQuery('');
                },
                icon: const Icon(Icons.filter_alt_off_outlined, size: 14),
                label: const Text('Clear filters & sort'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const HelpBanner(
            text:
                'Type in the search field to mark matches (Highlight) or '
                'drop non-matches (Filter — toggle the mode chip). Click '
                'any column header for sort + per-type filter dialog: '
                'Contains for text/date, Min/Max for numbers, true/false '
                'for bool.',
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
                theme: widget.theme,
                headerBuilder: (ctx, colId) => HeaderLabel(controller: _controller, colId: colId),
                onHeaderTap: (cellCtx, colId) => showUltimateColumnMenu(context: cellCtx, controller: _controller, colId: colId),
              ),
            ),
          ),
          _StatusBar(controller: _controller),
        ],
      ),
    );
  }
}

class _StatusBar extends StatefulWidget {
  final GridController controller;
  const _StatusBar({required this.controller});

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
  void dispose() {
    widget.controller.removeListener(_bump);
    super.dispose();
  }

  void _bump() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final view = widget.controller.pipelineResult.viewRowIndices.length;
    final filters = widget.controller.filters.length;
    final sorts = widget.controller.sortKeys.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Text('$view rows visible  ·  $filters filter(s)  ·  $sorts sort key(s)', style: const TextStyle(fontSize: 12)),
    );
  }
}
