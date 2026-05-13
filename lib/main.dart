import 'package:flutter/material.dart';

import 'examples/examples.dart';
import 'examples/source_viewer.dart';
import 'theme/mark85_theme.dart';

/// Single entry point for the example app.
///
/// Run with:
///   flutter run -t lib/main.dart
///   flutter run -t lib/main.dart -d chrome
///
/// Pick an example from the side-nav. Each example demonstrates a
/// different shape the package handles: timesheet (matrix with derived
/// edges), simple datagrid, full-feature datagrid (search / filter /
/// menu / async / copy), merged-cell spreadsheet, and a 5 M-row stress
/// test that exercises the canvas-paint body.
void main() => runApp(const UltimateTableApp());

class UltimateTableApp extends StatelessWidget {
  const UltimateTableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ultimate Table by CodeBigya',
      debugShowCheckedModeBanner: false,
      theme: buildMark85Theme(),
      home: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final example = examples[_selected];

    final exampleWithHeader = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExampleTopBar(example: example),
        Expanded(
          child: KeyedSubtree(
            key: ValueKey(_selected),
            child: example.build(context),
          ),
        ),
      ],
    );

    return Scaffold(
      drawer: compact
          ? Drawer(
              child: SafeArea(
                child: _SidebarList(
                  selected: _selected,
                  onSelect: (i) {
                    setState(() => _selected = i);
                    Navigator.of(context).maybePop();
                  },
                ),
              ),
            )
          : null,
      appBar: compact
          ? AppBar(
              title: _AppTitle(label: example.label),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              shape: const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            )
          : null,
      body: SafeArea(
        child: compact
            ? exampleWithHeader
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 240,
                    child: _Sidebar(
                      selected: _selected,
                      onSelect: (i) => setState(() => _selected = i),
                    ),
                  ),
                  const VerticalDivider(
                      width: 1, color: Color(0xFFE2E8F0)),
                  Expanded(child: exampleWithHeader),
                ],
              ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _Sidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFBF5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SidebarHeader(),
          Expanded(
            child: _SidebarList(selected: selected, onSelect: onSelect),
          ),
          const _SidebarFooter(),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.grid_view_rounded,
                    size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ultimate Table',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'by CodeBigya · examples',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarList extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _SidebarList({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: examples.length,
      itemBuilder: (ctx, i) {
        final e = examples[i];
        final active = i == selected;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Material(
            color: active ? const Color(0xFFFFF7ED) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelect(i),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      e.icon,
                      size: 18,
                      color: active
                          ? const Color(0xFFEA580C)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
                              color: active
                                  ? const Color(0xFFEA580C)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            e.subtitle,
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
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Text(
        'Tap an example to load it.',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
      ),
    );
  }
}

/// Thin header strip above each example. Shows the example's icon +
/// label + subtitle on the left, and a "View source" action on the
/// right that opens the backing .dart file in a selectable, copyable
/// viewer.
class _ExampleTopBar extends StatelessWidget {
  final ExampleEntry example;
  const _ExampleTopBar({required this.example});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(example.icon,
                size: 18, color: const Color(0xFFEA580C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  example.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => SourceViewer.show(
              context,
              assetPath: example.sourceAsset,
              title: example.sourceAsset.split('/').last,
            ),
            icon: const Icon(Icons.code, size: 16),
            label: const Text('View source'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              minimumSize: const Size(0, 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  final String label;
  const _AppTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Ultimate Table',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(width: 8),
        Text(
          '· $label',
          style: TextStyle(
            fontSize: 13,
            color: Colors.orange.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
