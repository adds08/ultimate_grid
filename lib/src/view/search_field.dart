import 'package:flutter/widgets.dart';

import '../controller/grid_controller.dart';
import '../filter_sort/filters.dart';

/// Pre-built global search input. Drives `controller.setSearchQuery` and
/// — if [showFilterToggle] is true — exposes a toggle between
/// `SearchMode.highlight` (default) and `SearchMode.filter` (drop non-matches).
///
/// Framework-agnostic: uses only `flutter/widgets.dart`. Style via the
/// constructor parameters or wrap in your own UI framework's input widget.
class UltimateSearchField extends StatefulWidget {
  final GridController controller;
  final String hintText;
  final double width;
  final bool showFilterToggle;
  final EdgeInsets padding;

  const UltimateSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search…',
    this.width = 240,
    this.showFilterToggle = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
  });

  @override
  State<UltimateSearchField> createState() => _UltimateSearchFieldState();
}

class _UltimateSearchFieldState extends State<UltimateSearchField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.controller.searchQuery);
    _ctrl.addListener(() {
      widget.controller.setSearchQuery(_ctrl.text);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.width,
          height: 32,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: widget.padding,
              child: Row(
                children: [
                  const Text('🔍',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                  const SizedBox(width: 6),
                  Expanded(
                    child: EditableText(
                      controller: _ctrl,
                      focusNode: FocusNode(),
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF0F172A)),
                      cursorColor: const Color(0xFF7C3AED),
                      backgroundCursorColor: const Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showFilterToggle) ...[
          const SizedBox(width: 8),
          _buildModeToggle(),
        ],
      ],
    );
  }

  Widget _buildModeToggle() {
    final mode = widget.controller.searchMode;
    return GestureDetector(
      onTap: () {
        widget.controller.setSearchMode(
          mode == SearchMode.highlight
              ? SearchMode.filter
              : SearchMode.highlight,
        );
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          mode == SearchMode.filter ? '▽ Filter' : '◈ Highlight',
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
      ),
    );
  }
}
