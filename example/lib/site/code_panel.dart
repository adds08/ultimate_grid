import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

/// Displays Dart source in a scrollable, monospaced, syntax-highlighted box
/// with a copy-to-clipboard button and a filename caption.
///
/// The source is loaded from the ACTUAL running `.dart` file via
/// [rootBundle] (snapshotted into `assets/source/` by `tool/sync_assets.dart`),
/// so the code shown == the code running — zero drift. When [region] is set it
/// extracts the lines between `// #docregion <region>` and
/// `// #enddocregion <region>` markers (markers themselves are stripped).
class CodePanel extends StatefulWidget {
  /// Asset key, e.g. `assets/source/screens/inventory_screen.dart`.
  final String assetPath;

  /// Caption under the panel (the real on-disk path).
  final String? label;

  /// Optional docregion name to extract.
  final String? region;

  /// Language for the highlighter.
  final String language;

  const CodePanel({
    super.key,
    required this.assetPath,
    this.label,
    this.region,
    this.language = 'dart',
  });

  @override
  State<CodePanel> createState() => _CodePanelState();
}

class _CodePanelState extends State<CodePanel> {
  late Future<String> _future;
  bool _copied = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(CodePanel old) {
    super.didUpdateWidget(old);
    if (old.assetPath != widget.assetPath || old.region != widget.region) {
      _future = _load();
    }
  }

  Future<String> _load() async {
    final raw = await rootBundle.loadString(widget.assetPath);
    return _extractRegion(raw, widget.region);
  }

  /// Returns lines between `// #docregion <name>` and `// #enddocregion <name>`
  /// (supporting multiple, possibly non-contiguous blocks for the same name).
  /// Marker lines are removed. Falls back to the whole file if not found.
  static String _extractRegion(String source, String? region) {
    if (region == null || region.isEmpty) return source.trimRight();
    final lines = source.split('\n');
    final out = <String>[];
    var inside = false;
    for (final line in lines) {
      final t = line.trim();
      if (t == '// #docregion $region') {
        inside = true;
        continue;
      }
      if (t == '// #enddocregion $region') {
        inside = false;
        continue;
      }
      // Skip unrelated region markers while inside so nested demos stay clean.
      if (inside &&
          (t.startsWith('// #docregion') || t.startsWith('// #enddocregion'))) {
        continue;
      }
      if (inside) out.add(line);
    }
    if (out.isEmpty) return source.trimRight();
    return out.join('\n').trimRight();
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _frame(
            child: const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            code: null,
          );
        }
        if (snap.hasError || snap.data == null) {
          return _frame(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load source (${widget.assetPath}).',
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            code: null,
          );
        }
        final code = snap.data!;
        final lineCount = '\n'.allMatches(code).length + 1;
        final tall = lineCount > 60;
        final viewportHeight = tall && !_expanded ? 520.0 : null;

        Widget highlighted = HighlightView(
          code,
          language: widget.language,
          theme: atomOneDarkTheme,
          padding: const EdgeInsets.all(16),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: ['Menlo', 'Consolas', 'monospace'],
            fontSize: 12.5,
            height: 1.5,
          ),
        );

        Widget scroller = Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.sizeOf(context).width.clamp(0, 900),
              ),
              child: highlighted,
            ),
          ),
        );

        if (viewportHeight != null) {
          scroller = SizedBox(
            height: viewportHeight,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(child: scroller),
            ),
          );
        }

        return _frame(code: code, child: scroller, tall: tall);
      },
    );
  }

  Widget _frame({
    required Widget child,
    required String? code,
    bool tall = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF282C34),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F232B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title bar with filename + copy.
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: const BoxDecoration(
              color: Color(0xFF21252B),
              border: Border(bottom: BorderSide(color: Color(0xFF181A1F))),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, size: 15, color: Color(0xFF7F848E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label ?? widget.assetPath,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFFABB2BF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (code != null)
                  TextButton.icon(
                    onPressed: () => _copy(code),
                    icon: Icon(
                      _copied ? Icons.check : Icons.copy_all_outlined,
                      size: 15,
                      color: _copied
                          ? const Color(0xFF98C379)
                          : const Color(0xFFABB2BF),
                    ),
                    label: Text(
                      _copied ? 'Copied' : 'Copy',
                      style: TextStyle(
                        fontSize: 12,
                        color: _copied
                            ? const Color(0xFF98C379)
                            : const Color(0xFFABB2BF),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),
          child,
          if (tall)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: const Color(0xFF21252B),
                child: Text(
                  _expanded ? 'Collapse' : 'Expand full source',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF61AFEF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
