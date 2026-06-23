import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../links.dart';
import '../site_shell.dart';

/// Renders a markdown asset loaded via rootBundle into a styled, scrollable
/// pane. Used by both the Docs and Roadmap pages. Fenced code blocks are
/// syntax-highlighted with the same theme as the live-example CodePanel so
/// docs and examples read identically.
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
          builders: {'code': _CodeBlockBuilder()},
        );
      },
    );
  }
}

/// Renders fenced code blocks with syntax highlighting. Inline code
/// (single-line, no language class) returns null so the default `code`
/// pill style applies.
class _CodeBlockBuilder extends MarkdownElementBuilder {
  static const _supported = {
    'dart',
    'yaml',
    'yml',
    'json',
    'bash',
    'shell',
    'sh',
  };

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final cls = element.attributes['class'];
    final hasLang = cls != null && cls.startsWith('language-');
    final text = element.textContent.trimRight();
    final isBlock = hasLang || text.contains('\n');
    if (!isBlock) return null; // inline code → default styling

    var lang = hasLang ? cls.substring('language-'.length) : 'dart';
    if (lang == 'yml') lang = 'yaml';
    if (lang == 'sh' || lang == 'shell') lang = 'bash';
    if (!_supported.contains(lang)) lang = 'dart';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF282C34),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1F232B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: HighlightView(
          text,
          language: lang,
          theme: atomOneDarkTheme,
          padding: const EdgeInsets.all(16),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: ['Menlo', 'Consolas', 'monospace'],
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
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
    // Inline code only (fenced blocks are handled by _CodeBlockBuilder).
    code: const TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: ['Menlo', 'Consolas', 'monospace'],
      fontSize: 13,
      backgroundColor: Color(0xFFF1F5F9),
      color: Color(0xFFBE123C),
    ),
    codeblockPadding: EdgeInsets.zero,
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
