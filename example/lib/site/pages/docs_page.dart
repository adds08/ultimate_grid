import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../site_shell.dart';
import 'markdown_view.dart';

/// Preferred ordering + friendly titles for known docs. Any file present in
/// the manifest but not listed here is appended (title derived from filename).
/// STATUS.md is intentionally excluded — it has its own /roadmap page.
const _preferred = <String, String>{
  'README.md': 'Overview',
  'getting-started.md': 'Getting started',
  'concepts.md': 'Concepts',
  'columns.md': 'Columns',
  'cells-and-rendering.md': 'Cells & rendering',
  'data-sources.md': 'Data sources',
  'interaction.md': 'Interaction',
  'sort-filter-search.md': 'Sort / filter / search',
  'theming.md': 'Theming',
  'performance.md': 'Performance',
  'recipes.md': 'Recipes',
};

/// A discovered doc page.
class _Doc {
  final String slug; // url segment (filename without .md)
  final String file; // filename
  final String title;
  const _Doc(this.slug, this.file, this.title);
}

/// Docs section: left nav of markdown files discovered at runtime + a right
/// pane rendering the selected file. Resilient to docs being added/removed.
class DocsPage extends StatefulWidget {
  /// Selected doc slug (filename without `.md`), or null for the first/index.
  final String? page;
  const DocsPage({super.key, this.page});

  @override
  State<DocsPage> createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> {
  late Future<List<_Doc>> _future;

  @override
  void initState() {
    super.initState();
    _future = _discover();
  }

  static String _titleFor(String file) {
    if (_preferred.containsKey(file)) return _preferred[file]!;
    final base = file.replaceAll('.md', '').replaceAll('-', ' ');
    return base.isEmpty ? file : base[0].toUpperCase() + base.substring(1);
  }

  Future<List<_Doc>> _discover() async {
    List<String> files;
    try {
      final raw = await rootBundle.loadString('assets/docs/_manifest.json');
      files = (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      files = _preferred.keys.toList();
    }
    // Drop STATUS.md (own page) and the manifest itself.
    files = files.where((f) => f.endsWith('.md') && f != 'STATUS.md').toList();

    // Order: preferred first (in declared order), then any extras.
    final ordered = <String>[];
    for (final p in _preferred.keys) {
      if (files.contains(p)) ordered.add(p);
    }
    for (final f in files) {
      if (!ordered.contains(f)) ordered.add(f);
    }
    return [
      for (final f in ordered) _Doc(f.replaceAll('.md', ''), f, _titleFor(f)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_Doc>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final docs = snap.data ?? const <_Doc>[];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Documentation is being written. Check back shortly, or read '
                'the source on GitHub.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kMuted),
              ),
            ),
          );
        }

        final selected = widget.page == null
            ? docs.first
            : docs.firstWhere(
                (d) => d.slug == widget.page,
                orElse: () => docs.first,
              );

        final width = MediaQuery.sizeOf(context).width;
        final compact = width < 860;

        final navList = _DocNav(
          docs: docs,
          selectedSlug: selected.slug,
          onTap: (slug) => context.go('/docs/$slug'),
        );

        final body = MarkdownView(
          key: ValueKey(selected.file),
          assetPath: 'assets/docs/${selected.file}',
        );

        if (compact) {
          return Column(
            children: [
              SizedBox(height: 52, child: navList),
              const Divider(height: 1, color: kBorder),
              Expanded(child: body),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 250, child: navList),
            const VerticalDivider(width: 1, color: kBorder),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: body,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DocNav extends StatelessWidget {
  final List<_Doc> docs;
  final String selectedSlug;
  final ValueChanged<String> onTap;
  const _DocNav({
    required this.docs,
    required this.selectedSlug,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 860) {
      // Horizontal scroller for compact layouts.
      return Container(
        color: const Color(0xFFFFFBF5),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          children: [
            for (final d in docs)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text(d.title),
                  selected: d.slug == selectedSlug,
                  onSelected: (_) => onTap(d.slug),
                ),
              ),
          ],
        ),
      );
    }
    return Container(
      color: const Color(0xFFFFFBF5),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Text(
              'DOCUMENTATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92400E),
                letterSpacing: 0.6,
              ),
            ),
          ),
          for (final d in docs)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              child: Material(
                color: d.slug == selectedSlug
                    ? const Color(0xFFFFF7ED)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onTap(d.slug),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Text(
                      d.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: d.slug == selectedSlug
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: d.slug == selectedSlug ? kBrandOrange : kInk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
