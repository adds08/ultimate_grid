import 'package:flutter/material.dart';

import 'markdown_view.dart';

/// Renders docs/STATUS.md — the single source of truth for what's shipped,
/// planned, and known-broken.
class RoadmapPage extends StatelessWidget {
  const RoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: const MarkdownView(assetPath: 'assets/docs/STATUS.md'),
      ),
    );
  }
}
