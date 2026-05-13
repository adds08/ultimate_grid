import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen dialog that loads a .dart file from `rootBundle` and shows
/// its text in a selectable, copyable, monospaced view. Used by the
/// example shell's "View source" button so callers can read and grab the
/// exact code that drives the active example.
class SourceViewer extends StatelessWidget {
  final String assetPath;
  final String title;

  const SourceViewer({
    super.key,
    required this.assetPath,
    required this.title,
  });

  /// Convenience: opens the viewer as a `Navigator.push` dialog.
  static Future<void> show(
    BuildContext context, {
    required String assetPath,
    required String title,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => SourceViewer(assetPath: assetPath, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.code, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          _CopyButton(assetPath: assetPath),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<String>(
        future: DefaultAssetBundle.of(context).loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Failed to load source: ${snapshot.error}',
                style: const TextStyle(color: Color(0xFFB91C1C)),
              ),
            );
          }
          final code = snapshot.data ?? '';
          return _CodeBody(code: code, assetPath: assetPath);
        },
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String assetPath;
  const _CopyButton({required this.assetPath});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    final ctx = context;
    final code =
        await DefaultAssetBundle.of(ctx).loadString(widget.assetPath);
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _copy,
      icon: Icon(_copied ? Icons.check : Icons.copy_outlined, size: 16),
      label: Text(_copied ? 'Copied' : 'Copy all'),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F172A)),
    );
  }
}

class _CodeBody extends StatelessWidget {
  final String code;
  final String assetPath;
  const _CodeBody({required this.code, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');
    final gutterWidth =
        (lines.length.toString().length * 9.0).clamp(28.0, 60.0);
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Scrollbar(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.sizeOf(context).width,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < lines.length; i++)
                        _CodeLine(
                          number: i + 1,
                          text: lines[i],
                          gutterWidth: gutterWidth,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeLine extends StatelessWidget {
  final int number;
  final String text;
  final double gutterWidth;
  const _CodeLine({
    required this.number,
    required this.text,
    required this.gutterWidth,
  });

  static const _codeStyle = TextStyle(
    fontFamily: 'Menlo',
    fontFamilyFallback: ['Consolas', 'Courier New', 'monospace'],
    fontSize: 13,
    height: 1.5,
    color: Color(0xFF0F172A),
  );
  static const _gutterStyle = TextStyle(
    fontFamily: 'Menlo',
    fontFamilyFallback: ['Consolas', 'Courier New', 'monospace'],
    fontSize: 12,
    height: 1.5,
    color: Color(0xFF94A3B8),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: gutterWidth,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              number.toString(),
              textAlign: TextAlign.right,
              style: _gutterStyle,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(text.isEmpty ? ' ' : text, style: _codeStyle),
          ),
        ),
      ],
    );
  }
}
