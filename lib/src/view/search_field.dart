import 'package:flutter/material.dart';

import '../controller/grid_controller.dart';
import '../filter_sort/filters.dart';

/// Pre-built global search input. Drives `controller.setSearchQuery` and
/// — if [showFilterToggle] is true — exposes a toggle between
/// `SearchMode.highlight` (default) and `SearchMode.filter` (drop non-matches).
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
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 16),
              isDense: true,
              contentPadding: widget.padding,
              hintText: widget.hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
    return TextButton.icon(
      onPressed: () {
        widget.controller.setSearchMode(
          mode == SearchMode.highlight
              ? SearchMode.filter
              : SearchMode.highlight,
        );
        setState(() {});
      },
      icon: Icon(
        mode == SearchMode.filter
            ? Icons.filter_alt
            : Icons.lightbulb_outline,
        size: 14,
      ),
      label: Text(
        mode == SearchMode.filter ? 'Filter' : 'Highlight',
        style: const TextStyle(fontSize: 12),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
