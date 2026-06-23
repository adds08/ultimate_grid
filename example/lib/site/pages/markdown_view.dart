import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';

import '../links.dart';
import '../site_shell.dart';

/// Renders a markdown asset loaded via rootBundle into a styled, scrollable
/// pane. Used by both the Docs and Roadmap pages.
class MarkdownView extends StatefulWidget {
  /// Asset key, e.g. `assets/docs/getting-started.md`.
  final String assetPath;
  const MarkdownView({super.key, required this.assetPath});

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = rootBundle.loadString(widget.assetPath);
  }

  @override
  void didUpdateWidget(MarkdownView old) {
    super.didUpdateWidget(old);
    if (old.assetPath != widget.assetPath) {
      _future = rootBundle.loadString(widget.assetPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snap.hasError || snap.data == null) {
          return Center(
            child: Text(
              'Could not load ${widget.assetPath}.',
              style: const TextStyle(color: kMuted),
            ),
          );
        }
        return Markdown(
          data: snap.data!,
          selectable: true,
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 60),
          onTapLink: (text, href, title) {
            if (href != null && href.startsWith('http')) openExternal(href);
          },
          styleSheet: _styleSheet(context),
        );
      },
    );
  }
}

MarkdownStyleSheet _styleSheet(BuildContext context) {
  return MarkdownStyleSheet(
    h1: const TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      color: kInk,
      height: 1.2,
    ),
    h2: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: kInk,
      height: 1.3,
    ),
    h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk),
    p: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.6),
    listBullet: const TextStyle(
      fontSize: 15,
      color: Color(0xFF334155),
      height: 1.6,
    ),
    a: const TextStyle(
      color: kBrandOrange,
      decoration: TextDecoration.underline,
    ),
    code: const TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      backgroundColor: Color(0xFFF1F5F9),
      color: Color(0xFFBE123C),
    ),
    codeblockDecoration: BoxDecoration(
      color: const Color(0xFF282C34),
      borderRadius: BorderRadius.circular(10),
    ),
    codeblockPadding: const EdgeInsets.all(16),
    blockquoteDecoration: BoxDecoration(
      color: const Color(0xFFFFFBF5),
      border: const Border(left: BorderSide(color: kBrandOrange, width: 3)),
      borderRadius: BorderRadius.circular(6),
    ),
    blockquotePadding: const EdgeInsets.all(12),
    tableHead: const TextStyle(fontWeight: FontWeight.w700, color: kInk),
    tableBorder: TableBorder.all(color: kBorder),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    horizontalRuleDecoration: const BoxDecoration(
      border: Border(top: BorderSide(color: kBorder)),
    ),
  );
}
